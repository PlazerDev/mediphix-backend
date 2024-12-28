import clinic_management_service.dao;
import clinic_management_service.model;
import ballerinax/mongodb;
import ballerina/io;
import ballerina/time;



public function mcsGetUserIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:mcsGetUserIdByEmail(email);
    return result;
}

public function mcsGetUpcomingSessionList(string userId) returns error|model:NotFoundError|model:McsAssignedSessionWithDoctorDetails[] {
    // get the assigned session id list
    // get the sessoions which are {overallSessionStatus = ACTIVE}
    // get the doctor details as well

    model:McsAssignedSessionWithDoctorDetails[] finalResult = [];    
    model:McsAssignedSessionIdList|mongodb:Error ? sessionIdList = dao:mcsGetAssignedSessionIdList(userId);

    if (sessionIdList is model:McsAssignedSessionIdList) {
        foreach string sessionId in sessionIdList.assignedSessions {
            
            model:McsAssignedSession|mongodb:Error ? sessionDetails = dao:mcsGetAssignedSessionDetails(sessionId);
            
            if(sessionDetails is mongodb:Error){
                return error("Database Error!");
            }
            
            if (sessionDetails is model:McsAssignedSession) {

                model:McsDoctorDetails|mongodb:Error ? doctorDetails = dao:mcsGetDoctorDetailsByID(sessionDetails.doctorId);

                if doctorDetails is model:McsDoctorDetails {
                    model:McsAssignedSessionWithDoctorDetails temp = {
                        endTimestamp: sessionDetails.endTimestamp,
                        startTimestamp: sessionDetails.startTimestamp,
                        doctorDetails: doctorDetails,
                        hallNumber: sessionDetails.hallNumber,
                        noteFromCenter: sessionDetails.noteFromCenter,
                        noteFromDoctor: sessionDetails.noteFromDoctor
                    };
                    finalResult.push(temp);
                }else if doctorDetails is mongodb:Error{
                    return error("Database Error: ", doctorDetails);
                }else {
                    return initNotFoundError("No matching doctor data for the provided session ID.");
                }
            } 
        }
        if (finalResult.length() == 0){
            return initNotFoundError("No matching upcomming sessions found");
        }
        return finalResult;
    } else if sessionIdList is mongodb:Error{
        return error("Database Error: ", sessionIdList);
    }else {
        return initNotFoundError("No assigned sessions found");
    }
}

public function mcsGetOngoingSessionList(string userId) returns error|model:NotFoundError|model:McsAssignedSessionWithDoctorDetails[] {
    
    model:McsAssignedSessionWithDoctorDetails[] finalResult = [];    
    model:McsAssignedSessionIdList|mongodb:Error ? sessionIdList = dao:mcsGetAssignedSessionIdList(userId);

    if (sessionIdList is model:McsAssignedSessionIdList) {
        foreach string sessionId in sessionIdList.assignedSessions {
            
            model:McsAssignedSession|mongodb:Error ? sessionDetails = dao:mcsGetOngoingSessionDetails(sessionId);
            if(sessionDetails is mongodb:Error){
                return error("Database Error!: ", sessionDetails);
            }
            
            if (sessionDetails is model:McsAssignedSession) {
                model:McsDoctorDetails|mongodb:Error ? doctorDetails = dao:mcsGetDoctorDetailsByID(sessionDetails.doctorId);

                if doctorDetails is model:McsDoctorDetails {
                    model:McsAssignedSessionWithDoctorDetails temp = {
                        endTimestamp: sessionDetails.endTimestamp,
                        startTimestamp: sessionDetails.startTimestamp,
                        doctorDetails: doctorDetails,
                        hallNumber: sessionDetails.hallNumber,
                        noteFromCenter: sessionDetails.noteFromCenter,
                        noteFromDoctor: sessionDetails.noteFromDoctor,
                        overallSessionStatus: sessionDetails.overallSessionStatus,
                        _id: sessionDetails._id
                    };
                    finalResult.push(temp);
                }else if doctorDetails is mongodb:Error{
                    return error("Database Error: ", doctorDetails);
                }else {
                    return initNotFoundError("No matching doctor data for the provided session ID.");
                }
            }
        }
        if (finalResult.length() == 0){
            return initNotFoundError("No matching ongoing sessions found");
        }
        return finalResult;
    } else if sessionIdList is mongodb:Error{
        return error("Database Error: ", sessionIdList);
    }else {
        return initNotFoundError("No assigned sessions found");
    }
}

public function mcsGetOngoingSessionTimeSlotDetails(string sessionId) returns error|model:NotFoundError|model:McsTimeSlotList {
    model:McsTimeSlotList|mongodb:Error ? result = dao:mcsGetOngoingSessionTimeSlotDetails(sessionId);

    if result is null {
        return initNotFoundError("Time slot data not found!");
    } else if result is mongodb:Error {
            return error("Database Error: ", result);
    } else {
        return result;
    }    
}

public function mcsStartAppointment(string sessionId, int slotId, string userId) returns error|model:NotFoundError|model:McsTimeSlot {
    
    // TODO :: check sessionId is assigned to the mcs user id
    if (!isSessionAssigned(sessionId, userId)) {
        return error("Session is not assigned to the user");
    }
    
    // get all the session details
    model:McsAssignedSession|mongodb:Error ? sessionResult = dao:mcsGetAllSessionDetails(sessionId);
    model:McsTimeSlot|mongodb:Error ? timeslotResult = dao:mcsGetTimeSlot(sessionId, slotId-1);

    if sessionResult is null {
        return initNotFoundError("Session Details Not Found !");
    } else if sessionResult is mongodb:Error {
        return error("Database Error: ", sessionResult);
    } else if timeslotResult is null{
        return initNotFoundError("Time slot data not found!");
    } else if timeslotResult is mongodb:Error {
        return error("Database Error: ", timeslotResult);
    } else{
        // check the overallsession is ONGOING and timeslot is STARTED
        if sessionResult.overallSessionStatus != "ONGOING" || timeslotResult.status != "STARTED" {
            return error("Invalid Operation");
        }else {
            // check whether their is a nextPatient1 or not
            int queueNumberOfNextPatient = timeslotResult.queue.queueOperations.nextPatient1;

            if (queueNumberOfNextPatient == -1) {
                return error("There is no next patient");
            }else {
                int aptNumber = timeslotResult.queue.appointments[queueNumberOfNextPatient-1];

                // check there is no ongoing appointment {ongoing == -1}
                if timeslotResult.queue.queueOperations.ongoing != -1 {
                    return error("There is a session ongoing!");
                }else {
                    // at this level all checks are passed in [session]
                    // if so change the {aptStatus} in [appointment] from "INQUEUE" to "ONGOING" using {aptNumber}
                    mongodb:UpdateResult|mongodb:Error updateAptStatusResult = dao:mcsUpdateAptStatus(aptNumber, "ONGOING", "INQUEUE");
                    if updateAptStatusResult is mongodb:UpdateResult {
                        if updateAptStatusResult.modifiedCount != 0 {
                            // update has been made successfully | Apt has set to ONGOING | No error should happen this point onward
                            model:McsQueueOperations newQueueOps = startNextAppointmentQueueHandler(timeslotResult.queue.appointments.length(), timeslotResult.queue.queueOperations);
                            sessionResult.timeSlot[slotId-1].queue.queueOperations = newQueueOps;
                            timeslotResult.queue.queueOperations = newQueueOps;
                            mongodb:Error|mongodb:UpdateResult result = dao:mcsUpdateQueueOperations(sessionId, slotId, sessionResult.timeSlot);
                            if(result is mongodb:Error){
                                return error("Databse error occured!");
                            }else {
                                if result.modifiedCount == 1 {
                                    return timeslotResult;
                                }else {
                                    // mongodb:UpdateResult|mongodb:Error rollbackAptStatus = dao:mcsUpdateAptStatus(aptNumber, "INQUEUE", "ONGOING");
                                    return error("Update Unsuccessfull!");
                                }
                            }
                        }else{
                            return initNotFoundError("Appointment status update failed");
                        }
                    }else{
                        return error("Database Error: ", updateAptStatusResult);
                    }
                }
            }
        }
    }
}

public function mcsStartTimeSlot(string sessionId, string userId) returns error|model:NotFoundError ? {
    
    // check :: session is assigned to the correct user
    if (!isSessionAssigned(sessionId, userId)) {
        return error("Session is not assigned to the user");
    }

    model:McsSession|mongodb:Error ? sessionResult = dao:mcsGetAllSessionData(sessionId);

    // check :: session is in ongoing Status
    if sessionResult is mongodb:Error {
        return error("Database Error");
    }else if sessionResult is null {
        return initNotFoundError("Session Data Not Found");
    }else {
        if sessionResult.overallSessionStatus == "ACTIVE" || sessionResult.overallSessionStatus == "ONGOING" {
            
            if sessionResult.timeSlot is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlot;
                int slotIdToBeStarted = findSlotToBeStarted(timeSlotResult);

                // check :: no active slots
                if slotIdToBeStarted < 0 {
                    return error("Active time slot found!");
                }else{
                    timeSlotResult[slotIdToBeStarted - 1].status = "STARTED";
                    // upadte the session and slot status
                    mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateSessionToStartAppointment(sessionId, timeSlotResult);   
                    if updateResult is mongodb:Error {
                        return error("Database Error");
                    }else {
                        if updateResult.modifiedCount == 1 {
                            // get all the appointments           
                            int[] aptList = <int[]> timeSlotResult[slotIdToBeStarted - 1].queue.appointments;
                            
                            updateResult= dao:mcsUpdateAptListStatus(aptList, "INQUEUE");
                            if updateResult is mongodb:Error {
                                return error("Database Error in updating appointment status");
                            }else {
                                return null;       
                            }
                        }else {
                            return initNotFoundError("Session Not Found to Update, Update Failed");
                        }
                    }
                }
            }else {
                return error("Database Error");
            }

           

        }else {
            return error("Session is either cancelled or over");
        }
    }

    // // get the list of time slot
    // model:McsTimeSlotList|mongodb:Error ? timeSlotResult = dao:mcsGetAllTimeSlotList(sessionId);




    // }
    
  
}

// HELPERS ............................................................................................................

public function initNotFoundError(string details) returns model:NotFoundError {
    model:ErrorDetails errorDetails = {
        message: "Not Found Error",
        details: details,
        timeStamp: time:utcNow()
    };
    model:NotFoundError notFound = {body: errorDetails};
    return notFound;
}

public function startNextAppointmentQueueHandler(int queueLength, model:McsQueueOperations mcsQueueOperations) returns model:McsQueueOperations{
    model:McsQueueOperations temp = mcsQueueOperations.clone();

    // exceptional case - where it only has 1 appointment and its being the first appointment 
    if queueLength == 1 {
        temp.nextPatient1 = -1;
        temp.nextPatient2 = -1;
        temp.ongoing = 1;
        temp.defaultIncrementQueueNumber = 1;
        return temp;
    }
    
    // update the ongoing
    temp.ongoing = temp.nextPatient1;


    int ? nextAvilableQueueNumber = getNextAvailablePatientQueueNumber(temp.defaultIncrementQueueNumber + 1, queueLength, mcsQueueOperations);
    if nextAvilableQueueNumber is null {
        // INFO:: no theoritical way to happen this since the newly ongoing patient is avilable in case
        io:println("WARNING! 233 on mcs_bal");
    }else {
        if nextAvilableQueueNumber == temp.ongoing {
            // update the defaultIncrementQueueNumber
            temp.defaultIncrementQueueNumber = nextAvilableQueueNumber;
        }
    }

    if temp.nextPatient2 != -1 {
        // update nextPatient1
        temp.nextPatient1 = temp.nextPatient2;
        // have to check this new next patient one is the supposed one
        nextAvilableQueueNumber = getNextAvailablePatientQueueNumber(temp.defaultIncrementQueueNumber + 1, queueLength, mcsQueueOperations);
         if nextAvilableQueueNumber is null {
            // this also therotically no way to happen since you had a nextPatient2
            io:println("WARNING! 249 on mcs_bal");
        }else {
            if nextAvilableQueueNumber == temp.nextPatient1 {
                nextAvilableQueueNumber = getNextAvailablePatientQueueNumber(temp.nextPatient1 + 1, queueLength, mcsQueueOperations);
                if nextAvilableQueueNumber is null {
                    temp.nextPatient2 = -1;
                }else {
                    temp.nextPatient2 = nextAvilableQueueNumber;
                }
            }else {
                temp.nextPatient2 = nextAvilableQueueNumber;
            }
        }
    }else {
        // update nextPatient1
        temp.nextPatient1 = -1;
    }
    return temp;
}

public function getNextAvailablePatientQueueNumber(int fromQueueNumber, int queueLength, model:McsQueueOperations mcsQueueOperations) returns int ? {
    int i = fromQueueNumber;
    while fromQueueNumber <= queueLength {
        if isMarkedAsAbsent(i, mcsQueueOperations) || isMarkedAsFinished(i, mcsQueueOperations) {
            i += 1;
        } else {
            return i;
        }
    }
    return null;
}

public function isMarkedAsAbsent(int queueNumber, model:McsQueueOperations mcsQueueOperations) returns boolean {
    boolean result = mcsQueueOperations.absent.indexOf(queueNumber) != null;
    if result {
        return true;
    }else {
        return false;
    }
}

public function isMarkedAsFinished(int queueNumber, model:McsQueueOperations mcsQueueOperations) returns boolean {
    boolean result = mcsQueueOperations.finished.indexOf(queueNumber) != null;
    if result {
        return true;
    }else {
        return false;
    }
}

public function isSessionAssigned(string sessionId, string userId) returns boolean {
    model:McsAssignedSessionIdList|mongodb:Error ? sessionIdList = dao:mcsGetAssignedSessionIdList(userId);

    if (sessionIdList is model:McsAssignedSessionIdList) {
        if sessionIdList.assignedSessions.indexOf(sessionId) != null {return true;} else {return false;}
    }else {
        return false;
    }
}

public function findSlotToBeStarted(model:McsTimeSlot[] data) returns int {
    
    int slotId = 1;

    foreach model:McsTimeSlot slot in data {
        if slot.status == "NOT_STARTED" {
            break;
        } else if slot.status == "STARTED" {
            slotId = -999;
            break;
        }else {
            slotId += 1;
        }
    }

    return slotId;
}


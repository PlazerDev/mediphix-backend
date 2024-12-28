import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;


public function createSessionVacancy(model:SessionVacancy sessionVacancy) returns http:Created|model:InternalError|error? {
    http:Created|error? vacancyResult = dao:createSessionVacancy(sessionVacancy);
    http:Created|error? sessionsResult = dao:createSessions(sessionVacancy);
    if (vacancyResult is http:Created) {
        return vacancyResult;
    }

    model:ErrorDetails errorDetails = {
        message: "Unexpected internal error occurred, please retry!",
        details: "sessionVacancy",
        timeStamp: time:utcNow()
    };

    model:InternalError internalError = {body: errorDetails};
    return internalError;
}

public function createSessions(model:SessionVacancy vacancy) returns http:Created|model:InternalError|error? {
    http:Created|error? result = dao:createSessions(vacancy);
    if (result is http:Created) {
        return result;
    }

    model:ErrorDetails errorDetails = {
        message: "Unexpected internal error occurred, please retry!",
        details: "sessions",
        timeStamp: time:utcNow()
    };

    model:InternalError internalError = {body: errorDetails};
    return internalError;
}

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

public function mcsStartAppointment(string sessionId, int slotId) returns error|model:NotFoundError|model:McsTimeSlot {
    
    // TODO :: check sessionId is assigned to the mcs user id
    
    
    // get all the session details
    model:McsAssignedSession|mongodb:Error ? sessionResult = dao:mcsGetAllSessionDetails(sessionId);
    model:McsTimeSlot|mongodb:Error ? timeslotResult = dao:mcsGetTimeSlot(sessionId, slotId-1);

    if sessionResult is null {
        return initNotFoundError("Session Details Not Found !");
    } else if sessionResult is mongodb:Error {
        return error("Database Error: ", sessionResult);
    } else if timeslotResult is null {
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
                            timeslotResult.queue.queueOperations = newQueueOps;
                            return timeslotResult;
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
            // update nextPatient2
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
                nextAvilableQueueNumber = getNextAvailablePatientQueueNumber(temp.defaultIncrementQueueNumber + 1, queueLength, mcsQueueOperations);
                if nextAvilableQueueNumber is null {
                    temp.nextPatient2 = -1;
                }else {
                    temp.nextPatient2 = nextAvilableQueueNumber;
                }
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
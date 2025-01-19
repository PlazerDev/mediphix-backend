import clinic_management_service.dao;
import clinic_management_service.model;
import ballerinax/mongodb;
import ballerina/io;
import ballerina/time;
import ballerina/log;



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
            
            log:printInfo("calling mcsGetOngoingSessionDetails to get session details", sessionId=sessionId);
            model:McsAssignedSession|mongodb:Error ? sessionDetails = dao:mcsGetOngoingSessionDetails(sessionId);
            log:printInfo("received");

            if(sessionDetails is mongodb:Error){
                return error("Database Error!: ", sessionDetails);
            }
            
            if (sessionDetails is model:McsAssignedSession) {
                log:printInfo("calling mcsGetDoctorDetailsByID to get doctor details", sessionId=sessionId);
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
                            sessionResult.timeSlots[slotId-1].queue.queueOperations = newQueueOps;
                            timeslotResult.queue.queueOperations = newQueueOps;
                            mongodb:Error|mongodb:UpdateResult result = dao:mcsUpdateQueueOperations(sessionId, slotId, sessionResult.timeSlots);
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
            
            if sessionResult.timeSlots is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlots;
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
}

public function mcsEndTimeSlot(string sessionId, string userId) returns error|model:NotFoundError ? {
    
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
        if sessionResult.overallSessionStatus == "ONGOING" {
            
            if sessionResult.timeSlots is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlots;
                int slotInStarted = findSlotInStarted(timeSlotResult);

                // check :: no active slots
                if slotInStarted < 0 {
                    return error("No active time slot found!");
                }else{
                    if timeSlotResult[slotInStarted - 1].queue.queueOperations.ongoing == -1 {
                        int ? nextAvlQueueNumber = getNextAvailablePatientQueueNumber(1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);
                        if nextAvlQueueNumber is null {
                            // update the timeslot status to FINISHED
                            timeSlotResult[slotInStarted - 1].status = "FINISHED";
                            mongodb:Error|mongodb:UpdateResult result = dao:mcsUpdateTimeSlotStatus(sessionId, timeSlotResult);
                            if result is mongodb:Error {
                                return error("Database error, while updating the time slot status");
                            }else {
                                if result.modifiedCount == 1 {
                                    // todo :: need to change the status of all appointment in the absend queue to "CANCELED"
                                    return null;
                                }else {
                                    return initNotFoundError("Session data not found, Update Failed");
                                }
                            }
                        }else {
                            return error("Action Failed, available appointment(s) found in the queue " + nextAvlQueueNumber.toString());
                        }
                        
                    }else {
                        return error("Action Failed, active appointment found!");
                    }
                }
            }else {
                return error("Database Error");
            }
        }else {
            return error("Session is not in ONGOING status");
        }
    }
}

public function mcsEndLastTimeSlot(string sessionId, string userId) returns error|model:NotFoundError ? {
    
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
        if sessionResult.overallSessionStatus == "ONGOING" {
            
            if sessionResult.timeSlots is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlots;
                int slotInStarted = findSlotInStarted(timeSlotResult);

                // check :: no active slots
                if slotInStarted < 0 {
                    return error("No active time slot found!");
                }else{
                    // check :: the time slot is the last one
                    if slotInStarted == timeSlotResult.length() {
                        // check :: no ongoing appointments
                        if timeSlotResult[slotInStarted - 1].queue.queueOperations.ongoing == -1 {
                            int ? nextAvlQueueNumber = getNextAvailablePatientQueueNumber(1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);
                            // check :: no avialble appointment in the current queue 
                            if nextAvlQueueNumber is null {
                                // update :: the timeslot status to FINISHED & session to OVER
                                timeSlotResult[slotInStarted - 1].status = "FINISHED";
                                mongodb:Error|mongodb:UpdateResult result = dao:mcsUpdateSessionToEndAppointment(sessionId, timeSlotResult);
                                if result is mongodb:Error {
                                    return error("Database error, while updating the time slot status");
                                }else {
                                    if result.modifiedCount == 1 {
                                        // uodate :: the status of all appointment in the absend queue to "CANCELED"
                                        int[] absentAppointmentsQueueNumbers = timeSlotResult[slotInStarted - 1].queue.queueOperations.absent;
                                        if absentAppointmentsQueueNumbers.length() > 0 {
                                            int[] absentAppointmentNumbers = getAppointmentNumbersFromQueueNumbers(timeSlotResult[slotInStarted - 1].queue);
                                            mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateAptListStatus(absentAppointmentNumbers, "CANCELED");
                                            if updateResult is mongodb:Error {
                                                return error("Database Error in updating appointment status to canceled");
                                            }else {
                                                return null;       
                                            }
                                        }
                                        return null;
                                    }else {
                                        return initNotFoundError("Session data not found, Update Failed");
                                    }
                                }
                            }else {
                                return error("Action Failed, available appointment(s) found in the queue " + nextAvlQueueNumber.toString());
                            }
                        }else {
                            return error("Action Failed, active appointment found!");
                        }
                    }else{
                        return error("Active slot is not the last one");
                    }
                }
            }else {
                return error("Database Error");
            }
        }else {
            return error("Session is not in ONGOING status");
        }
    }
}

public function mcsMoveToAbsent(string sessionId, int slotId, int aptNumber, string userId) returns error|model:NotFoundError ? {
    
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
        if sessionResult.overallSessionStatus == "ONGOING" {
            
            if sessionResult.timeSlots is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlots;
                int slotInStarted = findSlotInStarted(timeSlotResult);

                // check :: no active slots
                if slotInStarted < 0 {
                    return error("No active time slot found!");
                }else{
                    int ? queueNumber = timeSlotResult[slotInStarted - 1].queue.appointments.indexOf(aptNumber);
                    // check :: aptNumber is in the queue
                    if queueNumber is null {
                        return error("Invalid appointment number");
                    }else {
                        int actualQueueNumber = queueNumber + 1;
                        // chcek :: the location of the queue number
                        if isMarkedAsAbsent(actualQueueNumber, timeSlotResult[slotInStarted - 1].queue.queueOperations) {
                            // case :: already in the absent
                            return error("Relvent Appointment Number already in the absent queue"); 
                        }else if isMarkedAsFinished(actualQueueNumber, timeSlotResult[slotInStarted - 1].queue.queueOperations) {
                            // case :: appointment is in finish
                            return error("Appointment is already over");
                        }else if actualQueueNumber == timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 {
                            // case :: it set as next patient 1

                            // update :: add the queueNumber to absent
                            timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.push(actualQueueNumber);
                            
                            int ? nextPatientQueueNumber = getNextAvailablePatientQueueNumber(timeSlotResult[slotInStarted - 1].queue.queueOperations.defaultIncrementQueueNumber + 1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);
                            if nextPatientQueueNumber is null {
                                // case :: no next patient is available
                                // update :: set next patient 1 to -1, next patient 2 is already -1
                                timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = -1;
                            }else {
                                // case :: there is s next patient available 
                                if nextPatientQueueNumber == timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 {
                                    // case :: next available patient is the next patient 2 
                                    timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2;
                                    
                                    nextPatientQueueNumber = getNextAvailablePatientQueueNumber(timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 + 1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);
                                    if nextPatientQueueNumber is null {
                                        // case :: no next patient is available 
                                        // update :: next patient 2 to -1
                                        timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = -1;
                                    }else {
                                        // case :: there is a next patient 
                                        // update :: next patient 2 to available patient
                                        timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = nextPatientQueueNumber;
                                    }
                                }else {
                                    // case :: next available person is not the next patient 2 - means nextpatient 2 is overrided
                                    timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2;
                                    timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = nextPatientQueueNumber;
                                }
                            }
                            mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateTimeSlot(sessionId, timeSlotResult);
                            
                            if updateResult is mongodb:Error {
                                return error("Database error, while updating the time slot status");
                            }else {
                                if updateResult.modifiedCount == 1 {
                                    return null;
                                }else {
                                    return initNotFoundError("Session data not found, Update Failed");
                                }
                            }

                        } else if actualQueueNumber == timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 {
                            // case :: its set as next patient 2
                            // update :: next patient 2 to absent 
                            timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.push(actualQueueNumber);

                            int ? nextPatientQueueNumber = getNextAvailablePatientQueueNumber(timeSlotResult[slotInStarted - 1].queue.queueOperations.defaultIncrementQueueNumber + 1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);

                            if nextPatientQueueNumber is null {
                                // case :: no avaiable next patient , this will never be true, cuz nextpatient1 is there 
                            } else {

                                if nextPatientQueueNumber == timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 {
                                    // case :: next patient 1 is setted automatically 
                                    nextPatientQueueNumber = getNextAvailablePatientQueueNumber(timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 + 1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);

                                    if nextPatientQueueNumber is null {
                                        // case :: no any avaiable appointments
                                        // update :: set next patient 2 to -1 
                                         timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = -1;    
                                    }else {
                                        // case :: there is avaialble appointments
                                        // update :: set next patient 2 to avaiable patient 
                                        // TODO :: issue in here 
                                        timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = nextPatientQueueNumber;
                                    }
                                }else {
                                    // case :: next patient 1 is setted mannualy
                                    timeSlotResult[slotInStarted -1].queue.queueOperations.nextPatient2 = nextPatientQueueNumber;
                                }
                            }

                            mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateTimeSlot(sessionId, timeSlotResult);
                            
                            if updateResult is mongodb:Error {
                                return error("Database error, while updating the time slot status");
                            }else {
                                if updateResult.modifiedCount == 1 {
                                    return null;
                                }else {
                                    return initNotFoundError("Session data not found, Update Failed");
                                }
                            }

                        }else if actualQueueNumber == timeSlotResult[slotInStarted - 1].queue.queueOperations.ongoing {
                            // case :: its the ongoing one
                            return error("Appointment is in ongoing status");
                        }else {
                            // case :: its in the current queue
                            timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.push(actualQueueNumber);

                            // update :: append the queue number to absent 
                            mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateTimeSlot(sessionId, timeSlotResult);
                            
                            if updateResult is mongodb:Error {
                                return error("Database error, while updating the time slot status");
                            }else {
                                if updateResult.modifiedCount == 1 {
                                    return null;
                                }else {
                                    return initNotFoundError("Session data not found, Update Failed");
                                }
                            }
                        }
                    }
                }
            }else {
                return error("Database Error");
            }
        }else {
            return error("Session is not in ONGOING status");
        }
    }
}

public function mcsRevertFromAbsent(string sessionId, int slotId, int aptNumber, string userId) returns error|model:NotFoundError ? {
    
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
        if sessionResult.overallSessionStatus == "ONGOING" {
            
            if sessionResult.timeSlots is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlots;
                int slotInStarted = findSlotInStarted(timeSlotResult);

                // check :: no active slots
                if slotInStarted < 0 {
                    return error("No active time slot found!");
                }else{
                    int ? queueNumber = timeSlotResult[slotInStarted - 1].queue.appointments.indexOf(aptNumber);
                    // check :: aptNumber is in the queue
                    if queueNumber is null {
                        return error("Invalid appointment number");
                    }else {
                        int actualQueueNumber = queueNumber + 1;
                    
                        if isMarkedAsAbsent(actualQueueNumber, timeSlotResult[slotInStarted - 1].queue.queueOperations) {
                            // check :: queueNumber is in absent

                            if timeSlotResult[slotInStarted - 1].queue.queueOperations.defaultIncrementQueueNumber > actualQueueNumber {
                                // check :: has lost possition  
                                return error("Has lost the possition, please add to the end of queue");
                            }

                            int ? nextPatientQueueNumber = getNextAvailablePatientQueueNumber(timeSlotResult[slotInStarted - 1].queue.queueOperations.defaultIncrementQueueNumber + 1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);

                            if nextPatientQueueNumber is null {
                                // check :: no next patient

                                // update :: set the queue number to next patient1
                                timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = actualQueueNumber;

                            } else {
                                // check :: there is a next patient 

                                if nextPatientQueueNumber != timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 {
                                    // check :: the next avilable patient is not the nextpatient1
                                    
                                    if nextPatientQueueNumber != timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 {
                                        // check :: the next available patient is not the nextpatient2
                                        // status :: nextpatient1 is overided | nextpatient2 is overided 

                                        // nothing need to be done specifically

                                    }else {
                                        // check :: the next available patient is the nextpatient2
                                        // status :: nextpatient1 is overided | nextpatient2 is not overided 
                                        
                                        if actualQueueNumber < timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 {
                                            // check :: actual queue number has priority thatn the next patient 2
                                            // update :: nextpatient2
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = actualQueueNumber;
                                        }else {
                                            // nothing need to be done 
                                        }
                                    }
                                    
                                }else {
                                    // check :: the next available patient is the next patient 1
                                    nextPatientQueueNumber = getNextAvailablePatientQueueNumber(timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 + 1, timeSlotResult[slotInStarted - 1].queue.appointments.length(), timeSlotResult[slotInStarted - 1].queue.queueOperations);
                                    
                                    if nextPatientQueueNumber is null {
                                        // check :: no available patient after next patient 1
                                        // status :: nextpatient1 is not overided | no nextpatient2 
                                        if timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 > actualQueueNumber {
                                            // check :: queuenumber has more priority than next patient 1
                                            // update :: nextpatient1, nextpatient2
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1;
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = actualQueueNumber; 
                                        }else {
                                            // update :: next patient 2
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = actualQueueNumber;
                                        }

                                    }else if nextPatientQueueNumber == timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 {
                                        // check :: next availble patient is the next patient 2
                                        // status :: nextpatient1 is not overided | nextpatient2 is not overided

                                        if actualQueueNumber < timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 {
                                            // check  :: the precidency 
                                            // update :: nextpatient1, nextpatient2
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1;
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = actualQueueNumber;
                                        }else if actualQueueNumber < timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2{
                                            // check :: the precideny
                                            // update :: the nextpatient2
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = actualQueueNumber;
                                        }else {
                                            // check :: the queuenumber doesn't has priority
                                            // nothing to do 
                                        }
                                    }else {
                                        // check :: next availble patient is not the next patient 2
                                        // status :: nextpatient1 is not overided | nextpatient2 is overided 
                                        if actualQueueNumber < timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 {
                                            // check :: queue number has more priority than nextpatient1
                                            // update :: nextpatient1
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = actualQueueNumber;
                                        }else {
                                            // check :: queue number doesn't has more pririoty than nextpatient1
                                            // nothing to do
                                        }
                                    }
                                }

                            }

                            // update :: timslot, absent queue
                            int ? i = timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.indexOf(actualQueueNumber);
                            if i is null {
                                //  will not happen since we already check this before 
                                return error ("Unknown error");

                            }else {
                                // update :: remove the queue number from the absent 
                                int temp = timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.remove(i); 
                                if temp == actualQueueNumber {
                                    // just to ensure

                                    // update :: timeslot in db
                                    mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateTimeSlot(sessionId, timeSlotResult);
                                    if updateResult is mongodb:Error {
                                        return error("Database error, while updating the time slot status");
                                    }else {
                                        if updateResult.modifiedCount == 1 {
                                            return null;
                                        }else {
                                            return initNotFoundError("Session data not found, Update Failed");
                                        }
                                    }
                                } else {
                                    return error ("Error happen updating absent queue");
                                }
                            }

                        }else {
                            // check :: queueNumber is not in absent
                            return error("Appointment is not in the absent queue");
                        }
                    }
                }
            }else {
                return error("Database Error");
            }
        }else {
            return error("Session is not in ONGOING status");
        }
    }
}

public function mcsAddToEnd(string sessionId, int slotId, int aptNumber, string userId) returns error|model:NotFoundError ? {
    
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
        if sessionResult.overallSessionStatus == "ONGOING" {
            
            if sessionResult.timeSlots is model:McsTimeSlot[] {
                model:McsTimeSlot[] timeSlotResult = <model:McsTimeSlot[]> sessionResult.timeSlots;
                int slotInStarted = findSlotInStarted(timeSlotResult);
                
                // check :: no active slots
                if slotInStarted < 0 {
                    return error("No active time slot found!");
                }else{
                    int ? queueNumber = timeSlotResult[slotInStarted - 1].queue.appointments.indexOf(aptNumber);
                    // check :: aptNumber is in the queue
                    if queueNumber is null {
                        return error("Invalid appointment number");
                    }else {
                        int actualQueueNumber = queueNumber + 1;
                    
                        if isMarkedAsAbsent(actualQueueNumber, timeSlotResult[slotInStarted - 1].queue.queueOperations) {
                            // check :: queueNumber is in absent

                            if timeSlotResult[slotInStarted - 1].queue.queueOperations.defaultIncrementQueueNumber > actualQueueNumber {
                                // case :: has lost possition  
                                // update :: in appointments add the apt number to end of list, remove it from absent 
                                timeSlotResult[slotInStarted - 1].queue.appointments[actualQueueNumber - 1] = -1 * aptNumber;
                                timeSlotResult[slotInStarted - 1].queue.appointments.push(aptNumber);
                                int ? tempI = timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.indexOf(actualQueueNumber);
                                if tempI is int {
                                    int temp = timeSlotResult[slotInStarted - 1].queue.queueOperations.absent.remove(tempI);
                                    if temp == actualQueueNumber {
                                        // case ::will always true
                                        // check :: there is a nextpatient 1 or nextpatient 2
                                        if timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 == -1 {
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient1 = timeSlotResult[slotInStarted - 1].queue.appointments.length();
                                        }else if timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 == -1 {
                                            timeSlotResult[slotInStarted - 1].queue.queueOperations.nextPatient2 = timeSlotResult[slotInStarted - 1].queue.appointments.length();
                                        }else {
                                            // case :: nothing to do 
                                        }
                                    }else {
                                        return error("Unexpected error occured");
                                    }
                                }else {
                                    // will not happen bexause we check this earlier
                                }
                            }else{
                                // case :: has not lost the possition
                                return error("The appointment still has its original possition, please revert");
                            }

                            // update :: timeslot in db
                            mongodb:Error|mongodb:UpdateResult updateResult = dao:mcsUpdateTimeSlot(sessionId, timeSlotResult);
                            if updateResult is mongodb:Error {
                                return error("Database error, while updating the time slot status");
                            }else {
                                if updateResult.modifiedCount == 1 {
                                    return null;
                                }else {
                                    return initNotFoundError("Session data not found, Update Failed");
                                }
                            }
                        }else {
                            // check :: queueNumber is not in absent
                            return error("Appointment is not in the absent queue");
                        }
                    }
                }
            }else {
                return error("Database Error");
            }
        }else {
            return error("Session is not in ONGOING status");
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

public function initValueError(string details) returns model:ValueError {
    model:ErrorDetails errorDetails = {
        message: "Value Error",
        details: details,
        timeStamp: time:utcNow()
    };
    model:ValueError valueError = {body: errorDetails};
    return valueError;
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
    while i <= queueLength {
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

public function findSlotInStarted(model:McsTimeSlot[] data) returns int {
    
    int slotId = 1;

    foreach model:McsTimeSlot slot in data {
        if slot.status == "STARTED" {
            return slotId;
        }else {
            slotId += 1;
        }
    }

    return -999;
}

public function getAppointmentNumbersFromQueueNumbers(model:McsQueue data) returns int[] {
    int[] result = [];
    foreach int queueNumber in data.queueOperations.absent {
        result.push(data.appointments[queueNumber - 1]);
    }
    return result;
}
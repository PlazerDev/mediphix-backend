import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;
import ballerinax/mongodb;


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
            return error("Database Error!");
    } else {
        return result;
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
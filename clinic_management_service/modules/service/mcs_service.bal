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
    string[]|model:NotFoundError sessionIdList = check dao:mcsGetAssignedSessionIdList(userId);

    if (sessionIdList is string[]) {
        foreach string sessionId in sessionIdList {
            
            model:McsAssignedSession|mongodb:Error|error? sessionDetails = dao:mcsGetAssignedSessionDetails(sessionId);
            
            if(sessionDetails is mongodb:Error){
                return error("Database Error!");
            }
            
            if (sessionDetails is model:McsAssignedSession) {

                model:McsDoctorDetails|model:NotFoundError doctorDetails = check dao:mcsGetDoctorDetailsByID(sessionDetails.doctorId);

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
                }else if doctorDetails is model:NotFoundError{
                    return doctorDetails;
                }
            } 
        }
        if (finalResult.length() == 0){
            model:ErrorDetails errorDetails = {
                message: "Session not found",
                details: "No matching upcomming session found for the provided session ID.",
                timeStamp: time:utcNow()
            };
            model:NotFoundError notFound = {body: errorDetails};
            return notFound;
        }
        return finalResult;
    } else {
        return sessionIdList;
    }
}

public function mcsGetOngoingSessionList(string userId) returns error|model:NotFoundError|model:McsAssignedSessionWithDoctorDetails[] {
    
    model:McsAssignedSessionWithDoctorDetails[] finalResult = [];    
    string[]|model:NotFoundError sessionIdList = check dao:mcsGetAssignedSessionIdList(userId);

    if (sessionIdList is string[]) {
        foreach string sessionId in sessionIdList {
            
            model:McsAssignedSession|error?|mongodb:Error sessionDetails = dao:mcsGetOngoingSessionDetails(sessionId);
            if(sessionDetails is mongodb:Error){
                return error("Database Error!");
            }
            
            if (sessionDetails is model:McsAssignedSession) {

                model:McsDoctorDetails|model:NotFoundError doctorDetails = check dao:mcsGetDoctorDetailsByID(sessionDetails.doctorId);

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
                }else if doctorDetails is model:NotFoundError{
                    return doctorDetails;
                }
            }
        }
        if (finalResult.length() == 0){
            model:ErrorDetails errorDetails = {
                message: "Session not found",
                details: "No matching ongoing session found for the provided session ID.",
                timeStamp: time:utcNow()
            };
            model:NotFoundError notFound = {body: errorDetails};
            return notFound;
        }
        return finalResult;
    } else {
        return sessionIdList;
    }
}

public function mcsGetOngoingSessionTimeSlotDetails(string sessionId) returns error|model:NotFoundError|model:McsTimeSlotList {
    model:McsTimeSlotList|mongodb:Error ? result = dao:mcsGetOngoingSessionTimeSlotDetails(sessionId);

    if result is null {
        model:ErrorDetails errorDetails = {
                message: "Timeslot data not found",
                details: "No matching timeslot data for the provided session ID.",
                timeStamp: time:utcNow()
            };
        model:NotFoundError notFound = {body: errorDetails};
        return notFound;
    } else if result is mongodb:Error {
            return error("Database Error!");
    } else {
        return result;
    }    
}

import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerinax/mongodb;

// get the [userId] by [email]
public function mcaGetUserIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:mcaGetUserIdByEmail(email);
    return result;
}

// get all medical center staff memebrs details
public function mcaGetMCSdata(string userId) returns error|model:NotFoundError|model:McsFinalUserDataWithAssignedSession[] {
    model:MedicalCenterAdmin|mongodb:Error? mcaData = dao:getInfoMCA(userId);
    if mcaData is model:MedicalCenterAdmin {
        model:MedicalCenterBrief|mongodb:Error? centerData = dao:getInfoCenterByEmail(mcaData.medicalCenterEmail);
        if centerData is model:MedicalCenterBrief {
            model:MedicalCenterStaff[]|mongodb:Error? userData = dao:getInfoMCSByCenterId(centerData._id);
            if userData is null {
                return initNotFoundError("Center Staff Member data not found!");
            } else if userData is mongodb:Error {
                return initDatabaseError(userData);
            } else {
                model:McsFinalUserDataWithAssignedSession[] finalResult = [];

                foreach var user in userData {
                    model:McsSessionWithDoctorDetails[] result = [];
                    if (user.assignedSessions is string[]) {
                        string[] temp = user.assignedSessions ?: [];
                        foreach var sessionId in temp {
                            io:println("fetching details for this session id", sessionId);
                            var sessionDataWithDoctorData = dao:mcsGetAllSessionDataWithDoctorData(sessionId);
                            if (sessionDataWithDoctorData is model:McsSessionWithDoctorDetails) {
                                result.push(sessionDataWithDoctorData);
                            } else if (sessionDataWithDoctorData is null) {
                                // Stop execution and propagate the error
                                return initNotFoundError("Assigned Session Details Not Found");
                            } else {
                                // Stop execution and propagate the database error
                                return initDatabaseError(sessionDataWithDoctorData);
                            }
                        }
                    }
                    model:McsFinalUserDataWithAssignedSession temp = {
                        assignedsessionData: result,
                        userData: user
                    };
                    finalResult.push(temp);
                }

                return finalResult;
            }
        } else if centerData is null {
            return initNotFoundError("Medical center data not found");
        } else {
            return initDatabaseError(centerData);
        }
    } else if mcaData is null {
        return initNotFoundError("User specifc data not found");
    } else {
        return initDatabaseError(mcaData);
    }
}

// get all sessions in active
public function mcsGetActiveSessions(string userId) returns error|model:NotFoundError|model:McsSessionWithDoctorDetails[] {

    model:MedicalCenterAdmin|mongodb:Error? mcaData = dao:getInfoMCA(userId);
    if mcaData is model:MedicalCenterAdmin {
        model:MedicalCenterBrief|mongodb:Error? centerData = dao:getInfoCenterByEmail(mcaData.medicalCenterEmail);
        if centerData is model:MedicalCenterBrief {
            // change from here
            model:McsSessionWithDoctorDetails[]|mongodb:Error? result = dao:mcsGetAllActiveSessionDataWithDoctorData(centerData._id);
            if result is model:McsSessionWithDoctorDetails[] {
                return result;
            } else if result is null {
                return initNotFoundError("Session Data Not Found");
            } else {
                return initDatabaseError(result);
            }
        } else if centerData is null {
            return initNotFoundError("Medical center data not found");
        } else {
            return initDatabaseError(centerData);
        }
    } else if mcaData is null {
        return initNotFoundError("User specifc data not found");
    } else {
        return initDatabaseError(mcaData);
    }
}

// get all medical center reception memebrs details
public function mcaGetMCRdata(string userId) returns error|model:NotFoundError|model:MedicalCenterReceptionist[] {
    model:MedicalCenterAdmin|mongodb:Error? mcaData = dao:getInfoMCA(userId);
    if mcaData is model:MedicalCenterAdmin {
        model:MedicalCenterBrief|mongodb:Error? centerData = dao:getInfoCenterByEmail(mcaData.medicalCenterEmail);
        if centerData is model:MedicalCenterBrief {
            model:MedicalCenterReceptionist[]|mongodb:Error? userData = dao:getInfoMCRByCenterId(centerData._id);
            if userData is null {
                return initNotFoundError("Center Staff Reception data not found!");
            } else if userData is mongodb:Error {
                return initDatabaseError(userData);
            } else {
                return userData;
            }
        } else if centerData is null {
            return initNotFoundError("Medical center data not found");
        } else {
            return initDatabaseError(centerData);
        }
    } else if mcaData is null {
        return initNotFoundError("User specifc data not found");
    } else {
        return initDatabaseError(mcaData);
    }
}

// assign a session to the mcs member
public function mcaAssignSession(string sessionId, string mcsId, string userId) returns error|model:NotFoundError? {
    model:MedicalCenterAdmin|mongodb:Error? mcaData = dao:getInfoMCA(userId);
    if mcaData is model:MedicalCenterAdmin {
        model:MedicalCenterBrief|mongodb:Error? centerData = dao:getInfoCenterByEmail(mcaData.medicalCenterEmail);
        if centerData is model:MedicalCenterBrief {
            model:MedicalCenterStaff|mongodb:Error? userData = dao:getInfoMCSWithAssignedSession(mcsId);
            if userData is null {
                return initNotFoundError("Center Staff Member data not found!");
            } else if userData is mongodb:Error {
                return initDatabaseError(userData);
            } else {
                string[] temp = <string[]>userData.assignedSessions;
                if temp.indexOf(sessionId) is null {
                    // case :: can be added
                    // update 
                    temp.push(sessionId);
                    mongodb:Error? updateResult = check dao:updateAssignedSessionList(mcsId, temp);

                    if updateResult is null {
                        // case :: update sucess
                        return null;
                    } else if updateResult is mongodb:Error {
                        return initDatabaseError(updateResult);
                    }
                } else {
                    // case :: already found
                    return error("Already added one");
                }
            }
        } else if centerData is null {
            return initNotFoundError("Medical center data not found");
        } else {
            return initDatabaseError(centerData);
        }
    } else if mcaData is null {
        return initNotFoundError("User specifc data not found");
    } else {
        return initDatabaseError(mcaData);
    }
}

public function createSessionVacancy(model:NewSessionVacancy newSessionVacancy) returns http:Created|model:InternalError|error? {
    model:SessionVacancy sessionVacancy = {
        // initialize with required fields
        responses: [],
        aptCategories: newSessionVacancy.aptCategories,
        medicalCenterId: newSessionVacancy.medicalCenterId,
        mobile: newSessionVacancy.mobile,
        vacancyNoteToDoctors: newSessionVacancy.vacancyNoteToDoctors,
        openSessions: [],
        vacancyOpenedTimestamp: getCurrentCivilLKTime(),
        vacancyStatus: "OPEN"
    };
    foreach model:NewOpenSession newOpenSession in newSessionVacancy.openSessions {
        model:Repetition repetition = {
            isRepeat: newOpenSession.repetition.isRepeat,
            days: newOpenSession.repetition.days,
            noRepeatDateTimestamp: check time:civilFromString(newOpenSession.repetition.noRepeatDateTimestamp ?: "2000-10-03T10:15:30.00+05:30")
        };

        model:OpenSession openSession = {
            sessionId: 0,
            startTime: check time:civilFromString(newOpenSession.startTime),
            endTime: check time:civilFromString(newOpenSession.endTime),
            numberOfTimeslots: 0,
            rangeStartTimestamp: check time:civilFromString(newOpenSession.rangeStartTimestamp),
            rangeEndTimestamp: check time:civilFromString(newOpenSession.rangeEndTimestamp),
            repetition: repetition
        };
        time:Error? startTimeValidate = check time:dateValidate(openSession.startTime);
        time:Error? endTimeValidate = check time:dateValidate(openSession.endTime);
        if (startTimeValidate != null || endTimeValidate != null) {
            model:ErrorDetails errorDetails = {
                message: "Invalid date format",
                details: "startTime or endTime",
                timeStamp: time:utcNow()
            };

            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
        time:Utc startTimeUtc = check time:utcFromString(newOpenSession.startTime);
        time:Utc endTimeUtc = check time:utcFromString(newOpenSession.endTime);
        decimal diffSeconds = time:utcDiffSeconds(endTimeUtc, startTimeUtc);
        decimal diffHours = diffSeconds / 3600;
        openSession.numberOfTimeslots = <int>diffHours.round();
        sessionVacancy.openSessions.push(openSession);
    }

    http:Created|error? vacancyResult = dao:createSessionVacancy(sessionVacancy);
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

public function createSessions(model:SessionVacancy vacancy, model:SessionCreationDetails sessionCreationDetails) returns http:Created|model:InternalError|error? {
    http:Created|error? result = dao:createSessions(vacancy, sessionCreationDetails);
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

public function getMcaUserIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:getMcaUserIdByEmail(email);
    return result;
}

public function getMcaSessionVacancies(string userId) returns model:McaSessionVacancy[]|model:InternalError {
    model:McaSessionVacancy[]|model:InternalError|error result = dao:getMcaSessionVacancies(userId);

    if (result is model:McaSessionVacancy[]) {
        return result;
    }
    model:InternalError internalError = {
        body: {
            message: "Internal Error",
            details: "Error occurred while retrieving MCA session vacancies",
            timeStamp: time:utcNow()
        }
    };

    return internalError;
}

public function mcaAcceptDoctorResponseApplicationToOpenSession(string userId, string sessionVacancyId,int responseId, int appliedOpenSessionId, model:SessionCreationDetails sessionCreationDetails) returns http:Ok|model:InternalError|error {
    io:println("In service: mcaAcceptDoctorResponseApplicationToOpenSession");
    http:Ok|model:InternalError|error result = dao:mcaAcceptDoctorResponseApplicationToOpenSession(userId, sessionVacancyId,responseId, appliedOpenSessionId, sessionCreationDetails);
    io:println("result: ", result);
    if !(result is http:Ok) {
        model:InternalError internalError = {
            body: {
                message: "Internal Error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            }
        };
        return internalError;
    }
    return result;
}

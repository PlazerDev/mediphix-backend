import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;
import ballerina/io;

public function createSessionVacancy(model:NewSessionVacancy newSessionVacancy) returns http:Created|model:InternalError|error? {
    model:SessionVacancy sessionVacancy = {
        // initialize with required fields
        responses: [],
        aptCategories: newSessionVacancy.aptCategories,
        medicalCenterId: newSessionVacancy.medicalCenterId,
        mobile: newSessionVacancy.mobile,
        vacancyNoteToDoctors: newSessionVacancy.vacancyNoteToDoctors,
        openSessions: [],
        vacancyOpenedTimestamp: time:utcToCivil(time:utcNow())
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

public function getMcaUserIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:getMcaUserIdByEmail(email);
    return result;
}

public function getMcaSessionVacancies(string userId) returns model:SessionVacancy[]|model:InternalError {
    model:SessionVacancy[]|model:InternalError|error result = dao:getMcaSessionVacancies(userId);

    if (result is model:SessionVacancy[]) {
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

public function mcaAcceptDoctorResponseApplicationToOpenSession(string sessionVacancyId, int responseId, int appliedOpenSessionId) returns http:Ok|model:InternalError|error {
    http:Ok|model:InternalError|error result = dao:mcaAcceptDoctorResponseApplicationToOpenSession(sessionVacancyId, responseId, appliedOpenSessionId);
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

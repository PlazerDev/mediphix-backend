import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;

public function createSessionVacancy(model:NewSessionVacancy newSessionVacancy) returns http:Created|model:InternalError|error? {
    model:SessionVacancy sessionVacancy = {
        // initialize with required fields
        responses: [],
        aptCategories: newSessionVacancy.aptCategories,
        medicalCenterId: newSessionVacancy.medicalCenterId,
        mobileNumber: newSessionVacancy.mobileNumber,
        vacancyNoteToDoctors: newSessionVacancy.vacancyNoteToDoctors,
        openSessions: [],
        vacancyOpenedTimestamp: time:utcToCivil(time:utcNow())
    };
    foreach model:NewOpenSession newOpenSession in newSessionVacancy.openSessions {
        model:OpenSession openSession = {
            sessionId: 0,
            startTime: check time:civilFromString(newOpenSession.startTime),
            endTime: check time:civilFromString(newOpenSession.endTime),
            rangeStartTimestamp: check time:civilFromString(newOpenSession.rangeStartTimestamp),
            rangeEndTimestamp: check time:civilFromString(newOpenSession.rangeEndTimestamp),
            repetition: newOpenSession.repetition
        };
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

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

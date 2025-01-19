import clinic_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;

public function getMedicalCenterInfoByID(string id, string userId) returns model:MedicalCenter|model:NotFoundError|error? {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");

    map<json> filter = {_id: {"$oid": id}};
    model:MedicalCenter|error? findResults = check medicalCenterCollection->findOne(filter, {}, (), model:MedicalCenter);

    if findResults !is model:MedicalCenter {
        model:ErrorDetails errorDetails = {
            message: string `Failed to find medical center with id ${id}`,
            details: string `mcsMember/${userId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError notFoundError = {body: errorDetails};
        return notFoundError;
    }
    return findResults;
}

public function createSessionVacancy(model:SessionVacancy sessionVacancy) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionVacancyCollection = check mediphixDb->getCollection("session_vacancy");

    foreach model:OpenSession session in sessionVacancy.openSessions {
        if (session.sessionId === 0) {
            int|model:InternalError|error nextOpenSessionId = getNextOpenSessionId();
            if !(nextOpenSessionId is int) {
                return error("Failed to get next open session id");
            }
            session.sessionId = nextOpenSessionId;
        }
    }

    mongodb:Error? result = check sessionVacancyCollection->insertOne(sessionVacancy);

    return http:CREATED;
}

public function createSessions(model:SessionVacancy sessionVacancy) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    model:MedicalCenter|model:NotFoundError|error? medicalCenter = getMedicalCenterInfoByID(sessionVacancy.medicalCenterId, "");

    if (!(medicalCenter is model:MedicalCenter)) {
        return error("Medical center not found");
    }

    return http:CREATED;
}

public function createTimeslots(model:Session session) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection timeSlotCollection = check mediphixDb->getCollection("time_slot");

    foreach model:TimeSlot timeSlot in session.timeSlots {
        // timeSlot.slotId = timeSlot.timeSlotNumber ?: 0;
        mongodb:Error? result = check timeSlotCollection->insertOne(timeSlot);
    }

    return http:CREATED;
}

public function getNextTimeSlotNumber() returns int|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection counterCollection = check mediphixDb->getCollection("counters");

    map<json> filter = {"_id": "timeSlotNumber"};

    mongodb:Update update = {
        inc: {sequenceValue: 1}
    };

    mongodb:UpdateOptions options = {upsert: true};

    // Perform the update operation
    mongodb:UpdateResult|error result = check counterCollection->updateOne(filter, update, options);

    if (result is mongodb:UpdateResult) {
        log:printInfo("Timeslot number update successful.");
    } else {
        log:printError("Timeslot number update failed.", result);
        model:ErrorDetails errorDetails = {
            message: "Failed to update the appointment number counter",
            details: "appointment/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    model:Counter|error? findResults = check counterCollection->findOne(filter, {}, (), model:Counter);

    if findResults is model:Counter {
        return findResults.sequenceValue;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the timeslot number counter",
            details: "timeslot/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getNextOpenSessionId() returns int|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection counterCollection = check mediphixDb->getCollection("counters");

    map<json> filter = {"_id": "openSessionId"};

    mongodb:Update update = {
        inc: {sequenceValue: 1}
    };

    mongodb:UpdateOptions options = {upsert: true};

    // Perform the update operation
    mongodb:UpdateResult|error result = check counterCollection->updateOne(filter, update, options);

    if (result is mongodb:UpdateResult) {
        log:printInfo("Update successful.");
    } else {
        log:printError("Update failed.", result);
        model:ErrorDetails errorDetails = {
            message: "Failed to update the appointment number counter",
            details: "appointment/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    model:Counter|error? findResults = check counterCollection->findOne(filter, {}, (), model:Counter);

    if findResults is model:Counter {
        return findResults.sequenceValue;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the appointment number counter",
            details: "appointment/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getMcaUserIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Collection userCollection = check initDatabaseConnection("user");

    map<json> filter = {"email": email};
    map<json> projection = {
        "_id": {"$toString": "$_id"}
    };

    model:McaUserID|mongodb:Error? findResults = userCollection->findOne(filter, {}, projection);

    if findResults is model:McaUserID {
        return findResults._id;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving MCA ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function getMcaSessionVacancies(string userId) returns model:SessionVacancy[]|model:InternalError|error {
    string medicalCenterId = check getMcaAssociatedMedicalCenterId(userId);

    mongodb:Collection sessionVacancyCollection = check initDatabaseConnection("session_vacancy");
    map<json> filter = {"medicalCenterId": medicalCenterId};
    map<json> sessionProjection = {
        "_id": {"$toString": "$_id"},
        "responses": 1,
        "aptCategories": 1,
        "medicalCenterId": 1,
        "mobile": 1,
        "vacancyNoteToDoctors": 1,
        "openSessions": 1,
        "vacancyOpenedTimestamp": 1,
        "vacancyClosedTimestamp": 1,
        "centerName": 1,
        "profileImage": 1
    };

    stream<model:SessionVacancy, error?>|mongodb:Error? findResults = check sessionVacancyCollection->find(filter, {}, sessionProjection, model:SessionVacancy);

    if findResults is stream<model:SessionVacancy, error?> {

        model:SessionVacancy[]|error sessionVacancies = from model:SessionVacancy vacancy in findResults
            select vacancy;
        return sessionVacancies;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving MCA session vacancies",
            timeStamp: time:utcNow()
        };
        model:InternalError sessionVacancyNotFound = {body: errorDetails};

        return sessionVacancyNotFound;
    }
}

public function getMcaAssociatedMedicalCenterId(string userId) returns string|error {
    mongodb:Collection mcaCollection = check initDatabaseConnection("medical_center_admin");
    map<json> filter = {"userId": userId};
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "medicalCenterEmail": 1
    };
    model:McaMedicalCenterEmail|mongodb:Error? findResults = mcaCollection->findOne(filter, {}, projection, model:McaMedicalCenterEmail);

    if !(findResults is model:McaMedicalCenterEmail) {
        return error("Internal Error");
    }

    string medicalCenterEmail = findResults.medicalCenterEmail;

    mongodb:Collection medicalCenterCollection = check initDatabaseConnection("medical_center");

    map<json> emailFilter = {"email": medicalCenterEmail};
    projection = {
        "_id": {"$toString": "$_id"}
    };
    model:McaMedicalCenterId|mongodb:Error? findMedicalCenter = check medicalCenterCollection->findOne(emailFilter, {}, projection, model:McaMedicalCenterId);

    if !(findMedicalCenter is model:McaMedicalCenterId) {
        return error("Internal Error");
    }
    return findMedicalCenter._id;
}

public function mcaAcceptDoctorResponseApplicationToOpenSession(string sessionVacancyId, int responseId, int appliedOpenSessionId) returns http:Ok|model:InternalError|error {
    mongodb:Collection sessionVacancyCollection = check initDatabaseConnection("session_vacancy");
    map<json> sessionVacancyResponseFilter = {
        "_id": {"$oid": sessionVacancyId},
        "responses.responseId": responseId,
        "responses.responseApplications.appliedOpenSessionId": appliedOpenSessionId
    };
    io:println("Hello updating acceptance");
    map<json> sessionVacancyProjection = {
        "_id": {"$toString": "$_id"},
        "responses": 1,
        "aptCategories": 1,
        "medicalCenterId": 1,
        "mobile": 1,
        "vacancyNoteToDoctors": 1,
        "openSessions": 1,
        "vacancyOpenedTimestamp": 1,
        "vacancyClosedTimestamp": 1,
        "centerName": 1,
        "profileImage": 1
    };
    model:SessionVacancy|mongodb:Error? findResults = sessionVacancyCollection->findOne(sessionVacancyResponseFilter, {}, sessionVacancyProjection, model:SessionVacancy);
    io:println("Doctor response application found", findResults);
    

    mongodb:Update update = {
        "set": {
            "responses.$.responseApplications.$.isAccepted": true
        }
    };

    mongodb:UpdateResult|mongodb:Error? result = check sessionVacancyCollection->updateOne(sessionVacancyResponseFilter, update, {});

    if result is mongodb:UpdateResult {
        io:println("Doctor response application accepted successfully");
        return http:OK;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while updating response status",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};

        return internalError;
    }

}

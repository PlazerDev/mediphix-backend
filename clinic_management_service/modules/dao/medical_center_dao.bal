import clinic_management_service.model;

import ballerina/http;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/log;

public function getMedicalCenterInfoByID(string id, string userId) returns model:MedicalCenter|model:NotFoundError|error? {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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

    mongodb:Error? result = check sessionVacancyCollection->insertOne(sessionVacancy);

    return http:CREATED;
}

public function createSessions(model:SessionVacancy sessionVacancy) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");
    model:TimeSlot[] emptyTimeSlots = [];
    model:MedicalCenter|model:NotFoundError|error? medicalCenter = getMedicalCenterInfoByID(sessionVacancy.medicalCenterId, "");

    if (!(medicalCenter is model:MedicalCenter)) {
        return error("Medical center not found");
    }

    foreach model:Session session in sessionVacancy.sessions {
        session.doctorId = session.doctorId ?: "";
        session.doctorName = session.doctorName ?: "";
        session.doctorMobile = session.doctorMobile ?: "";
        session.medicalCenterName = medicalCenter.name;
        session.medicalCenterMobile = medicalCenter.mobile;
        session.doctorNote = session.doctorNote ?: "";
        session.medicalCenterNote = session.medicalCenterNote ?: "";
        session.sessionStatus = session.sessionStatus ?: "UNACCEPTED";
        session.location = session.location ?: "";
        session.payment = session.payment ?: 0.0;
        session.isAccepted = session.isAccepted ?: false;
        session.maxPatientCount = session.maxPatientCount ?: 0;
        session.reservedPatientCount = session.reservedPatientCount ?: 0;
        session.reservedPatientIds = session.reservedPatientIds ?: [];
        session.timeSlots = session.timeSlots.length() === 0 ? emptyTimeSlots : session.timeSlots;
        session.timeSlotIds = session.timeSlotIds.length() === 0 ? []: session.timeSlotIds;
        mongodb:Error? result = check sessionCollection->insertOne(session);
    }
    return http:CREATED;
}

public function createTimeslots(model:Session session) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection timeSlotCollection = check mediphixDb->getCollection("time_slot");

    foreach model:TimeSlot timeSlot in session.timeSlots {
        timeSlot.timeSlotNumber = timeSlot.timeSlotNumber ?: 0;
        mongodb:Error? result = check timeSlotCollection->insertOne(timeSlot);
    }
    return http:CREATED;
}

public function getNextTimeSlotNumber() returns int|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection counterCollection = check mediphixDb->getCollection("counters");

    map<json> filter = {"_id": "timeSlotNumber"};

    mongodb:Update update = {
        inc: {sequence_value: 1}
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

    model:TimeslotNumberCounter|error? findResults = check counterCollection->findOne(filter, {}, (), model:TimeslotNumberCounter);

    if findResults is model:TimeslotNumberCounter {
        return findResults.sequence_value;
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

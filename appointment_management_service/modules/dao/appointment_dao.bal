import appointment_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;

configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable string cluster = ?;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

public function createAppointmentRecord(model:AppointmentRecord appointmentRecord) returns http:Created|error? {

    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    check appointmentCollection->insertOne(appointmentRecord);
    
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    map<json> sessionFilter = {
        "_id": {"$oid": appointmentRecord.sessionId},
        "timeSlots.slotId": appointmentRecord.timeSlot
    };
    mongodb:Update sessionUpdate = {
        "push": {
            "timeSlots.$.queue.appointments": appointmentRecord.aptNumber
        }
    };

    mongodb:UpdateResult|error updateResult = sessionCollection->updateOne(
        sessionFilter,
        sessionUpdate
    );
    
    if updateResult is error {
        return updateResult;
    }

    if updateResult.modifiedCount == 0 {
        string errMsg = "Failed to update session. No matching session found.";
        return error(errMsg);
    }
    return http:CREATED;
}

public function getNextAppointmentNumber() returns int|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection counterCollection = check mediphixDb->getCollection("counters");

    map<json> filter = {"_id": "appointmentNumber"};

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

public function getAppointmentsByUserId(string userId) returns model:AppointmentRecord[]|model:InternalError|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    map<json> filter = {"patientId": {"$oid": userId}};

    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "aptNumber": 1,
        "sessionId": 1,
        "timeSlot": 1,
        "category": 1,
        "doctorId": 1,
        "doctorName": 1,
        "medicalCenterId": 1,
        "medicalCenterName": 1,
        "payment": 1,
        "aptCreatedTimestamp": 1,
        "aptStatus": 1,
        "patient": 1,
        "isPaid": 1,
        "queueNumber": 1,
        "medicalRecord": 1,
        "paymentTimeStamp": 1
    };

    stream<model:AppointmentRecord, error?> findResults = check appointmentCollection->find(filter, {}, projection, model:AppointmentRecord);

    model:AppointmentRecord[]|error appointments = from model:AppointmentRecord appointment in findResults
        select appointment;
    if appointments is model:AppointmentRecord[] {
        return appointments;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find appointments for the user",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};
        return userNotFound;
    }

}

public function getSessionDetailsByDoctorId(string doctorId) returns
model:Session[]|model:InternalError|model:NotFoundError|error? {
    io:println("Inside dao");
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    map<json> filter = {"doctorId": doctorId};
    io:println("Found doctor", filter);
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "endTimestamp": 1,
        "startTimestamp": 1,
        "timeSlots": 1,
        "doctorId": 1,
        "medicalCenterId": 1,
        "aptCategories": 1,
        "payment": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1,
        "overallSessionStatus": 1
    };

    stream<model:Session, error?>|error findStream = sessionCollection->find(filter, {}, projection, model:Session);
    if findStream is error {
         io:println("Error during find operation:", findStream.message());
        model:ErrorDetails errorDetails = {
            message: "Database error while finding sessions",
            details: findStream.message(),
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    stream<model:Session, error?> findResults = check findStream;

    model:Session[]|error sessions = from model:Session session in findResults
        select session;
    if sessions is model:Session[] {
        if sessions.length() == 0 {
            model:ErrorDetails errorDetails = {
                message: "No sessions found for the doctor",
                details: string `session/${doctorId}`,
                timeStamp: time:utcNow()
            };
            model:NotFoundError notFound = {body: errorDetails};
            return notFound;
        }
        return sessions;
    } else {
        io:println("Error during stream processing:", sessions.message());
        model:ErrorDetails errorDetails = {
            message: "Failed to find sessions for the doctor",
            details: string `session/${doctorId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};
        return userNotFound;
    }
}

public function getAppointmentByMobileAndNumber(string mobile, string appointmentNumber) returns model:Appointment|model:InternalError|model:NotFoundError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    map<json> filter = {"patientMobile": mobile};
    model:Appointment|error? findResults = check appointmentCollection->findOne(filter, {}, (), model:Appointment);
    if findResults is model:Appointment {
        return findResults;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the appointment for the given mobile number and appointment number",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError appointmentNotFound = {body: errorDetails};
        return appointmentNotFound;
    }

}

public function updateAppointmentStatus(string mobile, int appointmentNumber, model:AppointmentStatus status) returns http:Ok|model:InternalError|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    map<json> filter = {"patientMobile": mobile, "appointmentNumber": appointmentNumber};
    mongodb:Update update = {"set": {"status": string `${status}`}};
    mongodb:UpdateOptions options = {};
    mongodb:UpdateResult|error result = appointmentCollection->updateOne(filter, update, options);
    if (result is mongodb:UpdateResult) {
        if (result.matchedCount == 0) {
            log:printError("Failed to find the appointment for the given mobile number and appointment number");
            model:ErrorDetails errorDetails = {
                message: "Failed to find the appointment for the given mobile number and appointment number",
                details: string `appointment/${mobile}/${appointmentNumber}`,
                timeStamp: time:utcNow()
            };
            model:NotFoundError appointmentNotFound = {body: errorDetails};
            return appointmentNotFound;
        } else if (result.modifiedCount == 0) {
            log:printError("Failed to update the appointment status");
            model:ErrorDetails errorDetails = {
                message: "Failed to update the appointment status",
                details: string `appointment/${mobile}/${appointmentNumber}`,
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
        log:printInfo("Update successful.");
        return http:OK;
    }
    else {
        log:printError("Update failed.", result);
        model:ErrorDetails errorDetails = {
            message: "Failed to update the appointment status",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function updateMedicalRecord(model:MedicalRecord medicalRecord)
    returns http:Ok|model:InternalError|model:NotFoundError|error? {

    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    int aptNumber = medicalRecord.aptNumber;

    log:printInfo(string `Starting medical record update for appointment ${aptNumber}`);

    map<json> appointmentFilter = {"aptNumber": aptNumber};
    // Define projection to only retrieve needed fields
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "sessionId": 1,
        "timeSlot": 1,
        "queueNumber": 1
    };

    log:printInfo(string `Using appointment filter: ${appointmentFilter.toString()}`);

    // Use projection in findOne
    model:ProjectedAppointment|error? appointmentDoc = appointmentCollection->
        findOne(appointmentFilter, {}, projection, model:ProjectedAppointment);

    if appointmentDoc is error {
        log:printError(string `Error retrieving appointment document: ${appointmentDoc.message()}`);
        model:ErrorDetails errorDetails = {
            message: "Error retrieving appointment details",
            details: string `Failed to retrieve appointment/${aptNumber}`,
            timeStamp: time:utcNow()
        };
        return <model:InternalError>{body: errorDetails};
    }

    if appointmentDoc is () {
        log:printError(string `No appointment found for aptNumber: ${aptNumber}`);
        model:ErrorDetails errorDetails = {
            message: "Appointment not found",
            details: string `appointment/${aptNumber}`,
            timeStamp: time:utcNow()
        };
        return <model:NotFoundError>{body: errorDetails};
    }

    log:printInfo(string `Successfully retrieved appointment document: ${appointmentDoc.toString()}`);

    json medicalRecordJson = medicalRecord.toJson();
    mongodb:Update appointmentUpdate = {
        "set": {
            "medicalRecord": medicalRecordJson,
            "aptStatus": "OVER"
        }
    };

    mongodb:UpdateResult|error appointmentResult = appointmentCollection->updateOne(
        appointmentFilter,
        appointmentUpdate
    );

    if (appointmentResult is error) {
        log:printError("Error updating appointment", appointmentResult);
        model:ErrorDetails errorDetails = {
            message: "Error updating appointment",
            details: string `appointment/${aptNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    string sessionId = appointmentDoc.sessionId;
    int timeSlot = appointmentDoc.timeSlot;
    int queueNumber = appointmentDoc.queueNumber;

    map<json> sessionFilter = {
        "_id": {"$oid": sessionId},
        "timeSlot.slotId": timeSlot
    };
    mongodb:Update sessionUpdate = {
        "push": {
            "timeSlot.$.queue.queueOperations.finished": queueNumber
        },
        "set": {
            "timeSlot.$.queue.queueOperations.ongoing": -1
        }
    };

    mongodb:UpdateResult|error sessionResult = sessionCollection->updateOne(
        sessionFilter,
        sessionUpdate
    );

    if (sessionResult is error) {
        log:printError("Error updating session", sessionResult);
        model:ErrorDetails errorDetails = {
            message: "Error updating session",
            details: string `session/${sessionId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    if (appointmentResult is mongodb:UpdateResult && sessionResult is mongodb:UpdateResult) {
        if (appointmentResult.matchedCount == 0 || sessionResult.matchedCount == 0) {
            log:printError("No matching documents found for update");
            model:ErrorDetails errorDetails = {
                message: "No matching documents found for update",
                details: string `appointment/${aptNumber}`,
                timeStamp: time:utcNow()
            };
            model:NotFoundError notFoundError = {body: errorDetails};
            return notFoundError;
        } else if (appointmentResult.modifiedCount == 0 || sessionResult.modifiedCount == 0) {
            log:printError("Failed to update documents");
            model:ErrorDetails errorDetails = {
                message: "Failed to update documents",
                details: string `appointment/${aptNumber}`,
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }

        log:printInfo("Successfully updated both appointment and session documents");
        return http:OK;
    }
}

public function getOngoingAppointmentsByMobile(string mobile) returns model:Appointment[]|model:InternalError|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    map<json> filter = {
        "patientMobile": mobile,
        "status": "ONGOING"
    };
    stream<model:Appointment, error?> findResults = check appointmentCollection->find(filter, {}, (), model:Appointment);

    model:Appointment[]|error appointments = from model:Appointment appointment in findResults
        select appointment;
    if appointments is model:Appointment[] {
        return appointments;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find appointments for the given mobile number",
            details: string `appointment/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};
        return userNotFound;
    }

}

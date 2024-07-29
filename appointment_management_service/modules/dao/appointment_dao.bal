import appointment_management_service.model;

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;

configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable string cluster = ?;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

public function createAppointment(model:Appointment appointment) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    check appointmentCollection->insertOne(appointment);
    return http:CREATED;
}

public function getNextAppointmentNumber() returns int|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection counterCollection = check mediphixDb->getCollection("counters");

    map<json> filter = {"_id": "appointmentNumber"};

    mongodb:Update update = {
        inc: {sequence_value: 1}
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

    model:AppointmentNumberCounter|error? findResults = check counterCollection->findOne(filter, {}, (), model:AppointmentNumberCounter);

    if findResults is model:AppointmentNumberCounter {
        return findResults.sequence_value;
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

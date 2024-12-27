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

    model:AppointmentNumberCounter|error? findResults = check counterCollection->findOne(filter, {}, (), model:AppointmentNumberCounter);

    if findResults is model:AppointmentNumberCounter {
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

public function getAppointmentsByUserId(string userId) returns model:Appointment[]|model:InternalError|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    map<json> filter = {"patientId": {"$oid": userId}};

    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "appointmentNumber": 1,
        "doctorId": 1,
        "patientId": 1,
        "sessionId": 1,
        "category": 1,
        "medicalCenterId": 1,
        "medicalCenterName": 1,
        "isPaid": 1,
        "payment": 1,
        "status": 1,
        "appointmentTime": 1,
        "createdTime": 1,
        "lastModifiedTime": 1
    };

    stream<model:Appointment, error?> findResults = check appointmentCollection->find(filter, {}, projection, model:Appointment);

    model:Appointment[]|error appointments = from model:Appointment appointment in findResults
        select appointment;
    if appointments is model:Appointment[] {
        return appointments;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find appointments for the given mobile number",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};
        return userNotFound;
    }

}

public function getAppointmentsByDoctorId(string userId) returns model:Appointment[]|model:InternalError|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    map<json> filter = {"doctorId": userId};

    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "appointmentNumber": 1,
        "doctorId": 1,
        "patientId": 1,
        "sessionId": 1,
        "category": 1,
        "medicalCenterId": 1,
        "medicalCenterName": 1,
        "isPaid": 1,
        "payment": 1,
        "status": 1,
        "appointmentTime": 1,
        "createdTime": 1,
        "lastModifiedTime": 1
    };

    stream<model:Appointment, error?> findResults = check appointmentCollection->find(filter, {}, projection, model:Appointment);

    model:Appointment[]|error appointments = from model:Appointment appointment in findResults
        select appointment;
    if appointments is model:Appointment[] {
        return appointments;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find appointments for the given doctor",
            details: string `appointment/${userId}`,
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

    int aptNumber = medicalRecord.aptNumber;
    map<json> filter = {"apt_Number": aptNumber};
    
    json medicalRecordJson = medicalRecord.toJson();

    mongodb:Update update = {"$set": {"medical_record": medicalRecordJson}};

    // Define options for the update operation
    mongodb:UpdateOptions options = {};

    mongodb:UpdateResult|error result = appointmentCollection->updateOne(filter, update, options);

    if (result is mongodb:UpdateResult) {
        if (result.matchedCount == 0) {
            log:printError("No appointment found for the given apt_Number: " + aptNumber.toString());
            model:ErrorDetails errorDetails = {
                message: "Appointment not found for the given apt_Number",
                details: string `appointment/${aptNumber}`,
                timeStamp: time:utcNow()
            };
            model:NotFoundError notFoundError = {body: errorDetails};
            return notFoundError;
        } else if (result.modifiedCount == 0) {
            log:printError("Failed to update the medical record for apt_Number: " + aptNumber.toString());
            model:ErrorDetails errorDetails = {
                message: "Failed to update the medical record",
                details: string `appointment/${aptNumber}`,
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
        log:printInfo("Successfully updated the medical record for apt_Number: " + aptNumber.toString());
        return http:OK;
    } else {
        log:printError("Error occurred while updating the medical record", result);
        model:ErrorDetails errorDetails = {
            message: "An error occurred while updating the medical record",
            details: string `appointment/${aptNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
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

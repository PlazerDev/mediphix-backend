import clinic_management_service.model;

import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;

public function savePatient(model:Patient patient) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    if (patientCollection is mongodb:Collection) {
        check patientCollection->insertOne(patient);
    }
}

public function getPatientById(string userId) returns model:Patient|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
     map<json> filter = { "_id": { "$oid": userId } }; // Validate userId before passing it here

    // map<json> filter = { "nic" : "200011504872"};
     map<json> projection = {
        "_id": {"$toString": "$_id"},
        "mobile_number": 1,
        "first_name": 1,
        "last_name": 1,
        "nic": 1,
        "birthday": 1,
        "gender":1,
        "email": 1,
        "address": 1,
        "nationality": 1,
        "allergies": 1,
        "special_notes": 1
    };


    model:Patient|mongodb:Error? findResults = check patientCollection->findOne(filter, {}, projection, model:Patient);
       io:println("\n inside getpatine dao \n");

    if findResults !is model:Patient {

        model:ErrorDetails errorDetails = {
            message: string `Failed to find user with user id ${userId}`,
            details: string `patient/${userId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};

        return userNotFound;
    }
    return findResults;
}

public function getPatientByEmail(string email) returns model:Patient|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    map<json> filter = {"email": email};
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "mobile_number": 1,
        "first_name": 1,
        "last_name": 1,
        "nic": 1,
        "birthday": 1,
        "gender": 1,
        "email": 1,
        "address": 1,
        "nationality": 1,
        "allergies": 1,
        "special_notes": 1
    };
    model:Patient|error? findResults = check patientCollection->findOne(filter, {}, projection, model:Patient);
    if findResults !is model:Patient {
        model:ErrorDetails errorDetails = {
            message: string `Failed to find user with email ${email}`,
            details: string `patient/${email}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};

        return userNotFound;
    }
    return findResults;
}

public function getAppointments(string mobile) returns model:Appointment[]|error|model:ReturnResponse {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    map<json> filter = {
        "patientMobile": mobile,
        "status": {"$ne": ["CANCELLED", "OVER"]} // Filter out cancelled and over appointments

    };
    mongodb:FindOptions findOptions = {
        sort: {"appointmentDate": 1} // Sort by appointmentDate in ascending order
    };
    stream<model:Appointment, error?>|error? findResults = appointmentCollection->find(filter, findOptions, (), model:Appointment);

    if findResults is stream<model:Appointment, error?> {
        model:Appointment[]|error appointments = from model:Appointment appointment in findResults
            select appointment;
        return appointments;

    }

    else {
        model:ReturnResponse returnResponse = {
            message: "Database error occurred",
            statusCode: 500
        };
        return returnResponse;
    }

}

public function getAllDoctors() returns error|model:Doctor[]|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "slmc": 1,
        "nic": 1,
        "education": 1,
        "mobile": 1,
        "specialization": 1,
        "email": 1,
        "category": 1,
        "availability": 1,
        "verified": 1,
        "patients": [{"$toString": "$_id"}],
        "medical_centers": [{"$toString": "$_id"}],
        "sessions": [{"$toString": "$_id"}],
        "channellings": [{"$toString": "$_id"}],
        "medical_records": [{"$toString": "$_id"}],
        "lab_reports": [{"$toString": "$_id"}],
        "media_storage": 1
    };

    stream<model:Doctor, error?>|mongodb:Error? findResults = check doctorCollection->find({}, {}, projection, model:Doctor);
    if findResults is stream<model:Doctor, error?> {
        model:Doctor[]|error doctors = from model:Doctor mc in findResults
            select mc;
        return doctors;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving doctor details",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};
        return userNotFound;
    }
}

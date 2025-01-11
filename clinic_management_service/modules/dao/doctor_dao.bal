import clinic_management_service.model;

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;

//get doctorId by email
public function doctorIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

    map<json> filter = {"email": email};
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
    model:Doctor|mongodb:Error? findResults = check doctorCollection->findOne(filter, {}, projection);
    if findResults is model:Doctor {
        return findResults._id ?: "";
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving doctor ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function getSessionDetailsByDoctorId(string doctorId) returns error|model:InternalError|model:Session[] {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    map<json> sessionProjection = {
        "_id": {"$toString": "$_id"}, // Convert sessionId to string
        "doctorId": {"$toString": "$doctorId"}, // Convert doctorId to string
        "doctorName": 1, // Include doctorName as is
        "doctorMobile": 1, // Include doctorMobile as is
        "category": 1, // Include category as is
        "medicalCenterId": {"$toString": "$medicalCenterId"}, // Convert medicalCenterId to string
        "medicalCenterName": 1, // Include medicalCenterName as is
        "medicalCenterMobile": 1, // Include medicalCenterMobile as is
        "doctorNote": 1, // Include doctorNote as is
        "medicalCenterNote": 1, // Include medicalCenterNote as is
        "sessionDate": 1, // Include sessionDate as is
        "sessionStatus": 1, // Include sessionStatus as is
        "location": 1, // Include location as is
        "payment": 1, // Include payment as is
        "maxPatientCount": 1, // Include maxPatientCount as is
        "reservedPatientCount": 1, // Include reservedPatientCount as is
        "timeSlotId": [{"$toString": "$timeSlotId"}],
        "medicalStaffId": [{"$toString": "$medicalStaffId"}]
    };

    map<json> filter = {"_id": {"$oid": doctorId}};
    stream<model:Session, error?>|mongodb:Error? findResults = check sessionCollection->find(filter, {}, sessionProjection, model:Session);

    if findResults is stream<model:Session, error?> {
        model:Session[]|error Session = from model:Session ses in findResults
            select ses;
        return Session;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving session details",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }

}

//get my medical centers.in this method we find medical centers doctor array and find the medical centers which has the doctor
public function getMyMedicalCenters(string id) returns error|model:InternalError|model:MedicalCenter[] {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");

    map<json> filter = {"doctors": [id]};

    // Optional: You can specify which fields to retrieve in the projection
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "address": 1,
        "mobile": 1,
        "email": 1,
        "district": 1,
        "verified": 1,
        "profileImage": 1,
        "appointmentCategories": 1,
        "mediaStorage": 1,
        "specialNotes": 1,
        "doctors": 1,
        "appointments": 1,
        "patients": 1,
        "medicalCenterStaff": 1,
        "description": 1
    };

    stream<model:MedicalCenter, error?>|mongodb:Error? findResults = check medicalCenterCollection->find(filter, {}, projection, model:MedicalCenter);
    if findResults is stream<model:MedicalCenter, error?> {
        model:MedicalCenter[]|error medicalCenters = from model:MedicalCenter mc in findResults
            select mc;
        return medicalCenters;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving medical centers",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function getDoctorSessionVacancies(string doctorId) returns error|model:InternalError|model:SessionVacancy[] {
    model:Doctor|model:InternalError doctor = check getDoctorDetails(doctorId);
    string[] medicalCenters = [];
    if doctor is model:Doctor {
        medicalCenters = doctor.medical_centers ?: [];
    } else if (doctor is model:InternalError) {
        return doctor;
    }

    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionVacancyCollection = check mediphixDb->getCollection("session_vacancy");

    model:SessionVacancy[] sessionVacancies = [];

    foreach string medicalCenterId in medicalCenters {
        map<json> filter = {"medicalCenterId": medicalCenterId};

        // Optional: You can specify which fields to retrieve in the projection
        map<json> projection = {
            "_id": {"$toString": "$_id"},
            "responses": 1,
            "aptCategories": 1,
            "medicalCenterId": 1,
            "mobile": 1,
            "vacancyNoteToDoctors": 1,
            "openSessions": 1,
            "vacancyOpenedTimestamp": 1,
            "vacancyClosedTimestamp": 1
        };

        stream<model:SessionVacancy, error?>|mongodb:Error? findResults = check sessionVacancyCollection->find(filter, {}, projection, model:SessionVacancy);
        if findResults is stream<model:SessionVacancy, error?> {
            model:SessionVacancy[]|error sessionVacanciesTemp = from model:SessionVacancy sv in findResults
                select sv;
            if sessionVacanciesTemp is model:SessionVacancy[] {
                foreach model:SessionVacancy sv in sessionVacanciesTemp {
                    sessionVacancies.push(sv);
                }
            }
        } else {
            model:ErrorDetails errorDetails = {
                message: "Internal Error",
                details: "Error occurred while retrieving session vacancies",
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
    }

    return sessionVacancies;
}

public function respondDoctorToSessionVacancy(model:DoctorResponse response) returns http:Created|model:InternalError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionVacancyCollection = check mediphixDb->getCollection("doctor_response");
    int|model:InternalError|error nextDoctorResponseId = getNextDoctorResponseId();
    if nextDoctorResponseId is int {
        response.responseId = nextDoctorResponseId;
    } else if nextDoctorResponseId is model:InternalError {
        return nextDoctorResponseId;
    } else {
        return error("Failed to get next doctor response id");
    }
    check sessionVacancyCollection->insertOne(response);
    return http:CREATED;
}

public function getNextDoctorResponseId() returns int|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorResponseCollection = check mediphixDb->getCollection("counters");

    map<json> filter = {"_id": "doctorResponseId"};

    mongodb:Update update = {
        inc: {"sequenceValue": 1}
    };

    mongodb:UpdateOptions options = {upsert: true};

    mongodb:UpdateResult|error updateResult = check doctorResponseCollection->updateOne(filter, update, options);

    if updateResult is mongodb:UpdateResult {
        log:printInfo("Doctor response ID update successful.");
    } else {
        log:printError("Doctor response ID update failed.", updateResult);
        model:ErrorDetails errorDetails = {
            message: "Failed to update the doctor response ID counter",
            details: "doctorResponse/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    model:Counter|error? findResults = check doctorResponseCollection->findOne(filter, {}, (), model:Counter);
    if findResults is model:Counter {
        return findResults.sequenceValue;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the doctor response ID counter",
            details: "doctorResponse/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function getDoctorDetails(string id) returns error|model:Doctor|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

    map<json> filter = {"_id": {"$oid": id}};

    // Optional: You can specify which fields to retrieve in the projection
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
        "profileImage": 1,
        "patients": 1,
        "medical_centers": 1,
        "sessions": 1,
        "channellings": 1,
        "medical_records": 1,
        "lab_reports": 1,
        "media_storage": 1
    };
    model:Doctor|mongodb:Error? findResults = check doctorCollection->findOne(filter, {}, projection, model:Doctor);

    if findResults is model:Doctor {
        return findResults;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving doctor name",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function getDoctorDetails2(string id) returns error|model:Doctor|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

    map<json> filter = {"_id": {"$oid": id}};

    // Optional: You can specify which fields to retrieve in the projection
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
        "profileImage": 1,
        "patients": 1,
        "medical_centers": 1,
        "sessions": 1,
        "channellings": 1,
        "medical_records": 1,
        "lab_reports": 1,
        "media_storage": 1
    };
    model:Doctor|mongodb:Error? findResults = check doctorCollection->findOne(filter, {}, projection, model:Doctor);

    if findResults is model:Doctor {
        return findResults;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving doctor name",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}
public function getAllMedicalCenters() returns error|model:MedicalCenter[]|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "address": 1,
        "mobile": 1,
        "email": 1,
        "district": 1,
        "verified": 1,
        "profileImage": 1,
        "appointmentCategories": 1,
        "mediaStorage": 1,
        "specialNotes": 1,
        "doctors": [{"$toString": "$_id"}],
        "appointments": [{"$toString": "$_id"}],
        "patients": [{"$toString": "$_id"}],
        "medicalCenterStaff": [{"$toString": "$_id"}],
        "description": 1
    };
    stream<model:MedicalCenter, error?>|mongodb:Error? findResults = check medicalCenterCollection->find({}, {}, projection, model:MedicalCenter);
    if findResults is stream<model:MedicalCenter, error?> {
        model:MedicalCenter[]|error medicalCenters = from model:MedicalCenter mc in findResults
            select mc;
        return medicalCenters;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving medical centers",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};
        return userNotFound;
    }
}

public function getPatientIdByRefNumber(string refNumber)
    returns string|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    map<anydata>? appointment = check appointmentCollection->findOne({appointmentNumber: refNumber});

    if appointment is map<anydata> {
        anydata patientId = appointment["patientId"];
        if patientId is string {
            return patientId;
        } else {
            model:ErrorDetails errorDetails = {
                message: "Patient ID is not a string in the database.",
                details: "refNumber/" + refNumber,
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the appointment for the given reference number.",
            details: "refNumber/" + refNumber,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function setDoctorJoinRequest(model:DoctorMedicalCenterRequest req) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorRequestCollection = check mediphixDb->getCollection("doctor_join_request_to_mc");

    check doctorRequestCollection->insertOne(req);
    return http:CREATED;
}

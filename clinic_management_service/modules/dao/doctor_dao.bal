import clinic_management_service.model;

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;

//get doctorId by email
public function doctorIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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


public function getSessionDetailsByDoctorId(string doctorId) returns model:Session[]|model:InternalError|model:NotFoundError|error? {

    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    map<json> filter = {"doctorId": "673dad048e55ba9fafc9520f"};

    map<json> projection = {
        "_id": {"$toString": "$_id"}
    };
        
    stream<model:Session, error?>|mongodb:Error? findResults = check sessionCollection->find(filter, {}, projection, model:Session);
    if findResults is stream<model:Session, error?> {
        
        model:Session[]|error? sessions = from model:Session se in findResults
            select se;
        io:println(sessions);
        return sessions;
    } else {
        io:println("Error during stream processing:");
        model:ErrorDetails errorDetails = {
            message: "Failed to find sessions for the doctor",
            details: string `session/${doctorId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};
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
        "MedicalCenterStaff": 1,
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
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");

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
                    map<json> mcFilter = {"_id": {"$oid": sv.medicalCenterId}};
                    map<json> mcProjection = {
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
                        "MedicalCenterStaff": 1,
                        "description": 1
                    };
                    model:MedicalCenter|mongodb:Error? mcfindResults = check medicalCenterCollection->findOne(mcFilter, {}, mcProjection, model:MedicalCenter);
                    if (mcfindResults is model:MedicalCenter) {
                        sv.centerName = mcfindResults.name;
                        sv.profileImage = mcfindResults.profileImage;
                    }
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
    mongodb:Collection doctorResponseCollection = check initDatabaseConnection("doctor_response");
    int|model:InternalError|error nextDoctorResponseId = getNextDoctorResponseId();
    if nextDoctorResponseId is int {
        response.responseId = nextDoctorResponseId;
    } else if nextDoctorResponseId is model:InternalError {
        return nextDoctorResponseId;
    } else {
        return error("Failed to get next doctor response id");
    }
    check doctorResponseCollection->insertOne(response);
    mongodb:Collection sessionVacancyCollection = check initDatabaseConnection("session_vacancy");

    map<json> sessionVacancyFilter = {
        "_id": {"$oid": response.sessionVacancyId}
    };
    mongodb:Update sessionVacancyUpdate = {
        "push": {
            "responses": response.responseId
        }
    };

    mongodb:UpdateResult|error updateResult = sessionVacancyCollection->updateOne(
        sessionVacancyFilter,
        sessionVacancyUpdate
    );

    if updateResult is error {
        return updateResult;
    }

    if updateResult.modifiedCount == 0 {
        string errMsg = "Failed to update session vacancy. No matching session vacancy found.";
        return error(errMsg);
    }

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
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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
        "MedicalCenterStaff": [{"$toString": "$_id"}],
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

public function getPatientIdByRefNumber(int refNumber)
    returns string|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    io:println(refNumber);
    map<json> filter = {"aptNumber": refNumber};
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "aptNumber": 1,
        "sessionId": 1,
        "timeSlot": 1,
        "aptCategories": 1,
        "doctorId": 1,
        "doctorName": 1,
        "medicalCenterId": 1,
        "medicalCenterName": 1,
        "payment": 1,
        "aptCreatedTimestamp": 1,
        "aptStatus": 1,
        "patientId": 1,
        "patientName": 1,
        "queueNumber": 1
    };

   

    model:AppointmentRecord|mongodb:Error? appointment = check appointmentCollection->findOne(filter, {}, projection, model:AppointmentRecord);
  
    if appointment is model:AppointmentRecord {
        return appointment.patientId;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the appointment for the given reference number.",
            details: "refNumber/" ,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function getAptDetailsForOngoingSessions(int refNumber) returns model:AppointmentRecord|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    map<json> filter = {"aptNumber": refNumber};
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "aptNumber": 1,
        "sessionId": 1,
        "timeSlot": 1,
        "aptCategories": 1,
        "doctorId": 1,
        "doctorName": 1,
        "medicalCenterId": 1,
        "medicalCenterName": 1,
        "payment": 1,
        "aptCreatedTimestamp": 1,
        "aptStatus": 1,
        "patientId": 1,
        "patientName": 1,
        "queueNumber": 1
    };

    model:AppointmentRecord|mongodb:Error? appointment = check appointmentCollection->findOne(filter, {}, projection, model:AppointmentRecord);
    if appointment is model:AppointmentRecord {
        return appointment;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the appointment for the given reference number.",
            details: "refNumber/" ,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}


// public function getPatientIdByRefNumber(string refNumber)
//     returns string|model:InternalError|error {
//     mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
//     mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

//     map<anydata>? appointment = check appointmentCollection->findOne({appointmentNumber: refNumber});

//     if appointment is map<anydata> {
//         anydata patientId = appointment["patientId"];
//         if patientId is string {
//             return patientId;
//         } else {
//             model:ErrorDetails errorDetails = {
//                 message: "Patient ID is not a string in the database.",
//                 details: "refNumber/" + refNumber,
//                 timeStamp: time:utcNow()
//             };
//             model:InternalError internalError = {body: errorDetails};
//             return internalError;
//         }
//     } else {
//         model:ErrorDetails errorDetails = {
//             message: "Failed to find the appointment for the given reference number.",
//             details: "refNumber/" + refNumber,
//             timeStamp: time:utcNow()
//         };
//         model:InternalError internalError = {body: errorDetails};
//         return internalError;
//     }
// }

public function setDoctorJoinRequest(model:DoctorMedicalCenterRequest req) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorRequestCollection = check mediphixDb->getCollection("doctor_join_request_to_mc");

    check doctorRequestCollection->insertOne(req);
    return http:CREATED;
}

public function getOngoingSessionQueue(string doctorId) returns error|model:InternalError|model:Session[] {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

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

     map<json> filter = {
        "doctorId": doctorId,
        "overallSessionStatus": "ONGOING",
        "timeSlots": {
            "$elemMatch": {
                "status": "STARTED"
            }
        }
    };

    stream<model:Session, error?>|mongodb:Error? findResults = check sessionCollection->find(filter, {}, projection, model:Session);

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


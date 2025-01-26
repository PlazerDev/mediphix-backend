import clinic_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;

public function mcaGetUserIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Collection userCollection = check initDatabaseConnection("user");

    map<json> filter = {"email": email};
    map<json> projection = {
        "_id": {"$toString": "$_id"}

    };

    model:McsUserID|mongodb:Error? findResults = userCollection->findOne(filter, {}, projection);

    if findResults is model:McsUserID {
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

public function createSessions(model:SessionVacancy sessionVacancy, model:SessionCreationDetails sessionCreationDetails) returns http:Created|error? {

    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    model:MedicalCenter|model:NotFoundError|error? medicalCenter = getMedicalCenterInfoByID(sessionVacancy.medicalCenterId, "");

    foreach model:OpenSession openSession in sessionVacancy.openSessions {
        time:DayOfWeek dayOfTheWeek;
        if openSession.repetition.isRepeat {

            foreach string day in openSession.repetition.days {
                match day {
                    "SUN" => {
                        dayOfTheWeek = 0;
                    }
                    "MON" => {
                        dayOfTheWeek = 1;
                    }
                    "TUE" => {
                        dayOfTheWeek = 2;
                    }
                    "WED" => {
                        dayOfTheWeek = 3;
                    }
                    "THU" => {
                        dayOfTheWeek = 4;
                    }
                    "FRI" => {
                        dayOfTheWeek = 5;
                    }
                    "SAT" => {
                        dayOfTheWeek = 6;
                    }
                }

            }
        } else {

        }
    }

    if (!(medicalCenter is model:MedicalCenter)) {
        return error("Medical center not found");
    }

    return http:CREATED;
}

function isContainString(string[] array, string id) returns boolean {
    return array.indexOf(id) != ();
}

public function createTimeslots(model:Session session) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection timeSlotCollection = check mediphixDb->getCollection("time_slot");
    
    // foreach model:TimeSlot timeSlot in session.timeSlots {
    //     // timeSlot.slotId = timeSlot.timeSlotNumber ?: 0;
    //     mongodb:Error? result = check timeSlotCollection->insertOne(timeSlot);
    // }

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

public function getMcaSessionVacancies(string userId) returns model:McaSessionVacancy[]|model:InternalError|error {
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
        "vacancyStatus": 1,
        "centerName": 1,
        "profileImage": 1
    };

    stream<model:SessionVacancy, error?>|mongodb:Error? findResults = check sessionVacancyCollection->find(filter, {}, sessionProjection, model:SessionVacancy);

    if !(findResults is stream<model:SessionVacancy, error?>) {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving MCA session vacancies",
            timeStamp: time:utcNow()
        };
        model:InternalError sessionVacancyNotFound = {body: errorDetails};

        return sessionVacancyNotFound;

    }
    model:SessionVacancy[]|error sessionVacancies = from model:SessionVacancy vacancy in findResults
        select vacancy;

    if sessionVacancies is error {
        return sessionVacancies;
    }

    model:McaSessionVacancy[] mcaSessionVacancies = [];

    foreach model:SessionVacancy vacancy in sessionVacancies {
        model:McaDoctorResponse[] doctorResponses = [];
        foreach int responseId in vacancy.responses {

            map<json> doctorResponsesFilter = {
                "responseId": responseId
            };

            mongodb:Collection doctorResponseCollection = check initDatabaseConnection("doctor_response");

            map<json> doctorResponseProjection = {
                "responseId": 1,
                "submittedTimestamp": 1,
                "doctorId": 1,
                "sessionVacancyId": 1,
                "noteToPatient": 1,
                "vacancyNoteToCenter": 1,
                "responseApplications": 1,
                "isCompletelyRejected": 1
            };

            model:DoctorResponse|mongodb:Error? doctorResponse = check doctorResponseCollection->findOne(doctorResponsesFilter, {}, doctorResponseProjection, model:DoctorResponse);

            if !(doctorResponse is model:DoctorResponse) {
                return error("Internal Error");
            }

            map<json> doctorDetailsFilter = {
                "_id": {"$oid": doctorResponse.doctorId}
            };

            map<json> mcaSessionVacancyDoctorDetailsProjection = {
                "name": 1,
                "mobile": 1,
                "email": 1,
                "profileImage": 1
            };

            mongodb:Collection doctorCollection = check initDatabaseConnection("doctor");
            model:McaSessionVacancyDoctorDetails|mongodb:Error? mcaSessionVacancyDoctorDetails = check doctorCollection->findOne(doctorDetailsFilter, {}, mcaSessionVacancyDoctorDetailsProjection, model:McaSessionVacancyDoctorDetails);

            if !(mcaSessionVacancyDoctorDetails is model:McaSessionVacancyDoctorDetails) {
                return error("Internal Error");
            }

            model:McaDoctorResponse mcaDoctorResponse = {
                responseId: doctorResponse.responseId,
                submittedTimestamp: doctorResponse.submittedTimestamp,
                doctorId: doctorResponse.doctorId,
                doctorDetails: mcaSessionVacancyDoctorDetails,
                sessionVacancyId: doctorResponse.sessionVacancyId,
                noteToPatient: doctorResponse.noteToPatient,
                vacancyNoteToCenter: doctorResponse.vacancyNoteToCenter,
                responseApplications: doctorResponse.responseApplications,
                isCompletelyRejected: doctorResponse.isCompletelyRejected
            };

            doctorResponses.push(mcaDoctorResponse);
        }

        model:McaSessionVacancy mcaSessionVacancy = {
            _id: vacancy._id,
            responses: doctorResponses,
            aptCategories: vacancy.aptCategories,
            medicalCenterId: vacancy.medicalCenterId,
            mobile: vacancy.mobile,
            vacancyNoteToDoctors: vacancy.vacancyNoteToDoctors,
            openSessions: vacancy.openSessions,
            vacancyOpenedTimestamp: vacancy.vacancyOpenedTimestamp,
            vacancyClosedTimestamp: vacancy.vacancyClosedTimestamp,
            vacancyStatus: vacancy.vacancyStatus
        };
        mcaSessionVacancies.push(mcaSessionVacancy);
    }

    return mcaSessionVacancies;

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

public function mcaAcceptDoctorResponseApplicationToOpenSession(string userId, string sessionVacancyId, int responseId, int appliedOpenSessionId, model:SessionCreationDetails sessionCreationDetails) returns http:Ok|model:InternalError|error {
    mongodb:Collection doctorResponseCollection = check initDatabaseConnection("doctor_response");
    map<json> doctorResponseFilter = {
        "responseId": responseId,
        "responseApplications.appliedOpenSessionId": appliedOpenSessionId
    };

    map<json> doctorResponseProjection = {
        "responseId": 1,
        "submittedTimestamp": 1,
        "doctorId": 1,
        "sessionVacancyId": 1,
        "noteToPatient": 1,
        "vacancyNoteToCenter": 1,
        "responseApplications": 1,
        "isCompletelyRejected": 1
    };

    model:DoctorResponse|mongodb:Error? findResults = doctorResponseCollection->findOne(doctorResponseFilter, {}, doctorResponseProjection, model:DoctorResponse);
    io:println("Doctor response application found", findResults);

    mongodb:Update update = {
        "set": {
            "responseApplications.$.isAccepted": true
        }
    };

    mongodb:UpdateResult|mongodb:Error? result = check doctorResponseCollection->updateOne(doctorResponseFilter, update, {});

    if !(result is mongodb:UpdateResult) {

        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while updating response status",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};

        return internalError;
    }
    mongodb:Collection sessionVacancyCollection = check initDatabaseConnection("session_vacancy");
    map<json> filter = {
        _id: sessionVacancyId
    };
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
        "vacancyStatus": 1,
        "centerName": 1,
        "profileImage": 1
    };

    model:SessionVacancy|mongodb:Error? findResult = sessionVacancyCollection->findOne(filter, {}, sessionVacancyProjection, model:SessionVacancy);
    if (findResult is model:SessionVacancy) {
        // createSessions(findResult, sessionCreationDetails);
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving session vacancy",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};

        return internalError;
    }

    io:println("Doctor response application accepted successfully");

    return http:OK;
}


  # Fetch join reqs by center ID
    # 
    # 
    # + centerId - center ID
    # + return -  on success doctorId, reqId

public function getAllJoinReq(string centerId) returns model:JoinReq[]|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("doctor_join_request_to_mc");

    map<json> filter = {
        "medicalCenterId": centerId,
        "verified": false
    };

   map<json> projection = {
        "_id": {"$toString": "$_id"},
        "doctorId": 1
    };

    stream<model:JoinReq, error?> result = check collection->find(filter, {}, projection, model:JoinReq);
    
    model:JoinReq[]|error finalResult = from model:JoinReq userData in result select userData;
    if finalResult is model:JoinReq[] {
        return finalResult;
    } else {
        return null;
    }
}



  # Fetch breif doctor data for the joinReq by doctorId
    # 
    # 
    # + doctorId - center ID
    # + return -  on success centerlist, name, profile image

public function getBriefDoctorDataForJoinReq(string doctorId) returns model:DoctorReq|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("doctor");

    map<json> filter = {
         "_id": {"$oid": doctorId}
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "profileImage": 1,
        "medical_centers": 1
    };

    model:DoctorReq ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}
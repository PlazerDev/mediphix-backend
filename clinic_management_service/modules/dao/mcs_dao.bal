import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;




public function mcsGetUserIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");

    map<json> filter = {"email":email};
    map<json> projection = {
        "_id": {"$toString": "$_id"}
    
    };

    model:McsUserID|mongodb:Error? findResults = userCollection->findOne(filter, {}, projection);
    io:println("IN DAO -> RESULT: ",findResults);

    
    if findResults is model:McsUserID {
        return findResults._id;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving MCS ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function mcsGetAssignedSessionIdList(string userId) returns model:McsAssignedSessionIdList|mongodb:Error ? {    
    mongodb:Collection mcsCollection = check initDatabaseConnection("medical_center_staff");

    map<json> filter = {"userId": userId};
    map<json> projection = {
        "assignedSessions": 1,
        "_id": 0 
    };

    model:McsAssignedSessionIdList ? result = check mcsCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetAssignedSessionDetails(string sessionId) returns model:McsAssignedSession|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = {
        "_id": {"$oid": sessionId },
        "overallSessionStatus": "ACTIVE"
        };

    map<json> projection = {
        "_id": 0,
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1
    };

    model:McsAssignedSession ? result = check sessionCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetDoctorDetailsByID(string doctorId) returns model:McsDoctorDetails|mongodb:Error ?{
    mongodb:Collection doctorCollection = check initDatabaseConnection("doctor");

    map<json> filter = {
        "_id": {"$oid": doctorId }
        };

    map<json> projection = {
        "_id": 0,
        "name": 1,
        "profilePhoto": {"$toString": "$profileImage"},
        "education": 1,
        "specialization": 1
    };

    model:McsDoctorDetails ? result = check doctorCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetOngoingSessionDetails(string sessionId) returns model:McsAssignedSession|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = initOngoingSessionFilter(sessionId);

    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1,
        "overallSessionStatus": 1
    };

    model:McsAssignedSession ? result = check sessionCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetOngoingSessionTimeSlotDetails(string sessionId) returns model:McsTimeSlotList|mongodb:Error ? {    
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = initOngoingSessionFilter(sessionId);

    map<json> projection = {
        "_id": 0,
        "timeSlot": 1
    };

    model:McsTimeSlotList ? result = check sessionCollection->findOne(filter, {}, projection);
    return result;
}


// HELPERS ............................................................................................................
public function initDatabaseConnection(string collectionName) returns mongodb:Collection|mongodb:Error {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection collection = check mediphixDb->getCollection(collectionName);
    return collection;
}

public function initOngoingSessionFilter(string sessionId) returns map<json> {
    time:Utc currentTimeStamp = time:utcNow();

    json currentTimeJson = time:utcToCivil(currentTimeStamp).toJson();
    json hourAfterTimeJson = time:utcToCivil(time:utcAddSeconds(currentTimeStamp, 3600)).toJson();

    map<json> filter = {
        "_id": {"$oid": sessionId},
        "$or": [
            {"overallSessionStatus": "ONGOING"},
            {
                "$and": [
                    {"startTimestamp": {"$lte": currentTimeJson}},
                    {"endTimestamp": {"$gte": currentTimeJson}}
                ]
            },
            {
                "$and": [
                    {"startTimestamp": {"$lte": hourAfterTimeJson}},
                    {"endTimestamp": {"$gte": hourAfterTimeJson}}
                ]
            }
        ]
    };

    return filter;
}
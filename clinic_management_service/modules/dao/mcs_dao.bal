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

public function mcsGetAssignedSessionIdList(string userId) returns error|string[]|model:NotFoundError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection mcsCollection = check mediphixDb->getCollection("medical_center_staff");

    map<json> filter = {"userId": userId};
    map<json> projection = {
        "assignedSessions": 1,
        "_id": 0 
    };

    model:McsAssignedSessionIdList|mongodb:Error? findResult = mcsCollection->findOne(filter, {}, projection);

    // Handle the result or errors
    if findResult is model:McsAssignedSessionIdList {
        return findResult.assignedSessions;
    } else if findResult is mongodb:Error {
        return findResult; // Return the MongoDB error
    } else {

        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Not Found",
            timeStamp: time:utcNow()
        };
        model:NotFoundError notFound = {body: errorDetails};
        return notFound;
    }
}

public function mcsGetAssignedSessionDetails(string sessionId) returns error|model:McsAssignedSession|model:NotFoundError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

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

    model:McsAssignedSession|mongodb:Error? result = sessionCollection->findOne(filter, {}, projection);

    if result is model:McsAssignedSession {
        return result;
    }else if result is mongodb:Error {
        return result;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Not Found",
            timeStamp: time:utcNow()
        };
        model:NotFoundError notFound = {body: errorDetails};
        return notFound;
    }
}

public function mcsGetDoctorDetailsByID(string doctorId) returns model:McsDoctorDetails|error|model:NotFoundError{
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

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

    model:McsDoctorDetails|mongodb:Error? result = doctorCollection->findOne(filter, {}, projection);

    if result is model:McsDoctorDetails {
        return result;
    }else if result is mongodb:Error {
        return result;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Not Found",
            timeStamp: time:utcNow()
        };
        model:NotFoundError notFound = {body: errorDetails};
        return notFound;
    }
}
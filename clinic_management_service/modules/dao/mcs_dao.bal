import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;

public function getMCSInfoByUserID(string userId) returns model:MCS|model:NotFoundError|error?{    
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection mcsCollection = check mediphixDb->getCollection("medical_center_staff");

    map<json> filter = { "user_id": userId };
    model:MCS|error? findResults = check mcsCollection->findOne(filter, {}, (), model:MCS);

    if findResults !is model:MCS {
        model:ErrorDetails errorDetails = {
            message: string `Failed to find user with user id ${userId}`,
            details: string `mcsMember/${userId}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};
        return userNotFound;
    }
    return findResults;
}

public function getMcsIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");

    map<json> filter = {"email":email};
    map<json> projection = {
        "_id": {"$toString": "$_id"}
    
    };

    model:McsUserID|mongodb:Error? findResults = userCollection->findOne(filter, {},projection);
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


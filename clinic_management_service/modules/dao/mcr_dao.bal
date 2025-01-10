import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;


public function mcrGetUserIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Collection userCollection = check initDatabaseConnection("user");

    map<json> filter = {"email":email};
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
            details: "Error occurred while retrieving MCR ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

// HELPERS ............................................................................................................

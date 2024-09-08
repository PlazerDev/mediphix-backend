import clinic_management_service.model;

// import ballerina/io;
import ballerina/time;
import ballerinax/mongodb;

public function getLabByEmail(string mobile) returns model:Patient|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    map<json> filter = {"mobile_number": mobile};
    model:Patient|error? findResults = check patientCollection->findOne(filter, {}, (), model:Patient);
    if findResults !is model:Patient {
        model:ErrorDetails errorDetails = {
            message: string `Failed to find user with mobile number ${mobile}`,
            details: string `patient/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};

        return userNotFound;
    }
    return findResults;
}



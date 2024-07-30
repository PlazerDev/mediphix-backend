import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;

public function getMedicalCenterInfoByID(string id, string userId) returns model:Medical_Center|model:NotFoundError|error?{    
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");
    
    map<json> filter = { _id: {"$oid" : id}};
    model:Medical_Center|error? findResults = check medicalCenterCollection->findOne(filter, {}, (), model:Medical_Center);
 
    if findResults !is model:Medical_Center {
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

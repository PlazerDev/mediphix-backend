import clinic_management_service.model;

import ballerina/time;
import ballerinax/mongodb;

configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable string cluster = ?;

public function savePatient(model:Patient patient) returns error? {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");

    // Patient patient = {
    //     mobile_number: "0787654321",
    //     first_name: "Kavindi",
    //     last_name: "Ranathunga",
    //     nic: "987654321V",
    //     birthday: "1999-05-15",
    //     email: "kavindirana@gmail.com",
    //     address: {
    //         house_number: "56/7",
    //         street: "Temple Road",
    //         city: "Mount Lavinia",
    //         province: "Western",
    //         postal_code: "10370"
    //     },
    //     allergies: ["Pollen", "Dust"],
    //     special_notes: ["Requires follow-up on previous condition", "Has a history of asthma"]
    // };

    check patientCollection->insertOne(patient);
}

public function getPatient(string mobile) returns model:Patient|model:UserNotFound|error? {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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
        model:UserNotFound userNotFound = {body: errorDetails};

        return userNotFound;
    }
    return findResults;
}

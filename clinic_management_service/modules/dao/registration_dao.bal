// import ballerina/http;

import clinic_management_service.model;

import ballerina/io;
import ballerinax/mongodb;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

public function reg() returns stream<model:User, error?>|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("users");
    stream<model:User, error?> findResult = check patientCollection->find();
    return findResult;
}

public function save(model:User user) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("users");
    check patientCollection->insertOne(user);
}

public function patientRegistration(model:PatientSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    model:Patient patient = {
        mobile_number: data.mobile,
        first_name: data.fname,
        last_name: data.lname,
        birthday: data.dob,
        email: data.email,
        nic: data.nic,
        address: data.address,
        nationality: data.nationality,
        allergies: [],
        special_notes: []

    };
    return check patientCollection->insertOne(patient);
}

public function isPatientExist(string mobile) returns boolean|error? {
 
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");

    map<json> filter = {"mobile_number": mobile};

 
    int|error? patientResult =  patientCollection->countDocuments(filter, {});


    if (patientResult === 0) {
        return false;
    } 
    else {
        return true; 
    }
}

function saveOnAsgardio() {
    io:println("Save on Asgardio");
}

function registerPatient() {

}

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
public function doctorRegistration(model:DoctorSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");
    
    model:Doctor doctor = {
        name: data.name,
        slmc: data.slmc,
        nic: data.nic,
        education: data.education,
        mobile: data.mobile,
        specialization: data.specialization,
        email: data.email,
        hospital: "not assigned",
        category: "not assigned",
        availability: "not assigned",
        fee: 0.0,
        verified: false
    };
    model:User doctorUser = {
        email: data.email,
        role: "doctor",
        password: data.password
    };
    error? insertedUser =check userCollection->insertOne(doctorUser);
    if(insertedUser is error){
        return insertedUser;
    }
    else{
        return check doctorCollection->insertOne(doctor);
    }
    
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

//check whether the doctor is already exist in user collection or doctor collection
public function isDoctorExist(string email) returns boolean|error? {
 
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");

    map<json> filter = {"email": email};

 
    int|error? userResult =  userCollection->countDocuments(filter, {});
    int|error? doctorResult =  doctorCollection->countDocuments(filter, {});


    if (userResult === 0 && doctorResult === 0) {
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

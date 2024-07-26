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
public function medicalCenterRegistration(model:otherSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");
    
    model:MedicalCenter mc={
        name: data.name,
        address: data.address,
        mobile: data.mobile,
        email: data.email,
        idfront: data.idfront,
        idback: data.idback,
        district: data.district,
        verified: false,
        fee: 0.0
    };
    model:User mcUser = {
        email: data.email,
        role: "medical center",
        password: data.password
    };
    error? insertedUser =check userCollection->insertOne(mcUser);
    if(insertedUser is error){
        return insertedUser;
    }
    else{
        return check medicalCenterCollection->insertOne(mc);
    }
    
}
public function laborataryRegistration(model:otherSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection laborataryCollection = check mediphixDb->getCollection("laboratary");
    
   model:Laboratary lab={
        name: data.name,
        address: data.address,
        mobile: data.mobile,
        email: data.email,
        idfront: data.idfront,
        idback: data.idback,
        district: data.district,
        verified: false,
        fee: 0.0
    };
    model:User mcUser = {
        email: data.email,
        role: "medical center",
        password: data.password
    };
    error? insertedUser =check userCollection->insertOne(mcUser);
    if(insertedUser is error){
        return insertedUser;
    }
    else{
        return check laborataryCollection->insertOne(lab);
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
public function isMedicalCenterExist(string email) returns boolean|error? {
 
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCEnterCollection = check mediphixDb->getCollection("medical_center");
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");

    map<json> filter = {"email": email};

 
    int|error? userResult =  userCollection->countDocuments(filter, {});
    int|error? medicalcenterResult =  medicalCEnterCollection->countDocuments(filter, {});


    if (userResult === 0 && medicalcenterResult === 0) {
        return false;
    } 
    else {
        return true; 
    }
}
public function isLaborataryExist(string email) returns boolean|error? {
 
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection laborataryCollection = check mediphixDb->getCollection("laboratary");
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");

    map<json> filter = {"email": email};

 
    int|error? userResult =  userCollection->countDocuments(filter, {});
    int|error? labResult =  laborataryCollection->countDocuments(filter, {});


    if (userResult === 0 && labResult === 0) {
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

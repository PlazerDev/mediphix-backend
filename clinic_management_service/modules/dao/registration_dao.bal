import clinic_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerinax/mongodb;

configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable string cluster = ?;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string bearerTokenEndpoint = ?;
configurable string scimEndpoint = ?;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

# Description.
#
# + tokenEndpoint - endpoint to get the token  
# + clientId - client id save in the config.TOML file
# + clientSecret - client secret save in the config.TOML file
# + return - return the access token
public isolated function fetchBeareToken(string tokenEndpoint, string clientId, string clientSecret) returns string|error {
    final http:Client clientEndpoint = check new (tokenEndpoint);
    string authHeader = string `${clientId}:${clientSecret}`;
    http:Request tokenRequest = new;
    tokenRequest.setHeader("Authorization", "Basic " + authHeader.toBytes().toBase64());
    tokenRequest.setHeader("Content-Type", "application/json");
    tokenRequest.setPayload({
        "grant_type": "client_credentials",
        "scope": "internal_user_mgt_create"
    });
    json resp = check clientEndpoint->post("/oauth2/token", tokenRequest);
    string accessToken = check resp.access_token;
    return accessToken;
}

# Description.
#
# + tokenEndpoint - asgardio SCIM API endpoint
# + token - the token return from the fetchBeareToken function
# + payload - the user data to be added
# + return - return the response from the asgardio
public isolated function addUser(string tokenEndpoint, string token, json payload) returns json|error {
    final http:Client clientEndpoint = check new (tokenEndpoint);
    string authHeader = string `Bearer ${token}`;
    http:Request tokenRequest = new;
    tokenRequest.setHeader("Authorization", authHeader);
    tokenRequest.setHeader("Content-Type", "application/scim+json");
    tokenRequest.setHeader("Accept", "application/scim+json");
    tokenRequest.setPayload(payload);
    json resp = check clientEndpoint->post("/scim2/Users", tokenRequest);

    return resp;
}

public function patientRegistration(model:PatientSignupData data) returns error?|json {
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
    mongodb:Error? insertOne = patientCollection->insertOne(patient);
    if insertOne is mongodb:DatabaseError {
        return insertOne;
    }
    //asgardio integration part 
    else {
        string bToken = check fetchBeareToken(bearerTokenEndpoint, clientId, clientSecret);
        json userData = {
            schemas: [],
            name: {
                givenName: data.fname,
                familyName: data.lname
            },
            userName: "DEFAULT/" + data.email,
            password: "Visal@9988",
            emails: [
                {
                    value: data.email,
                    primary: true
                }
            ],
            phoneNumbers: [
                {
                    value: data.mobile
                }              
            ],

            "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
                manager: {
                    value: ""
                }
            },
            "urn:scim:wso2:schema": {
                verifyEmail: false
            }
        };
        json|error? resp = addUser(scimEndpoint, bToken, userData);
        return resp;
    }
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
    error? insertedUser = check userCollection->insertOne(doctorUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        return check doctorCollection->insertOne(doctor);
    }

}

public function medicalCenterRegistration(model:otherSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");

    model:MedicalCenter mc = {
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
    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        return check medicalCenterCollection->insertOne(mc);
    }

}

public function laborataryRegistration(model:otherSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection laborataryCollection = check mediphixDb->getCollection("laboratary");

    model:Laboratary lab = {
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
    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        return check laborataryCollection->insertOne(lab);
    }

}

public function isPatientExist(string mobile) returns boolean|error? {

    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");

    map<json> filter = {"mobile_number": mobile};

    int|error? patientResult = patientCollection->countDocuments(filter, {});

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

    int|error? userResult = userCollection->countDocuments(filter, {});
    int|error? doctorResult = doctorCollection->countDocuments(filter, {});

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

    int|error? userResult = userCollection->countDocuments(filter, {});
    int|error? medicalcenterResult = medicalCEnterCollection->countDocuments(filter, {});

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

    int|error? userResult = userCollection->countDocuments(filter, {});
    int|error? labResult = laborataryCollection->countDocuments(filter, {});

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

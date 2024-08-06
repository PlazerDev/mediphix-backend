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
configurable string doctorRoleId = ?;
configurable string patientRoleId = ?;
configurable string mcsRoleId = ?;
configurable string laborataryRoleId = ?;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
string endPoint = string `https://api.asgardeo.io/t/mediphix`;

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
        "scope": "internal_user_mgt_create internal_user_mgt_list internal_user_mgt_view internal_role_mgt_update internal_role_mgt_view"
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

# Description-This function used for search the role and get the role id.
#
# + token - Bearer token  
# + roleName - Role name to be search..this name should be same as the role name in the asgardio
# + return - return the role ID string
public isolated function searchRole(string token, string roleName) returns error|string {
    string endPoint = string `https://api.asgardeo.io/t/mediphix/scim2/v2/Roles/.search`;
    json payload = {
        "schemas": [
            "urn:ietf:params:scim:api:messages:2.0:SearchRequest"
        ],
        "startIndex": 1,
        "count": 10,
        "filter": string `displayName eq ${roleName}`
    };
    final http:Client clientEndpoint = check new (endPoint);
    string authHeader = string `Bearer ${token}`;
    http:Request tokenRequest = new;
    tokenRequest.setHeader("Authorization", authHeader);
    tokenRequest.setHeader("Content-Type", "application/scim+json");
    tokenRequest.setHeader("Accept", "application/scim+json");

    tokenRequest.setPayload(payload);
    model:scimSearchResponse resp = check clientEndpoint->post("/scim2/v2/Roles/.search", tokenRequest);
    io:println(resp);
    string roleId = check resp.Resources[0].id;
    return roleId;
}

# this function use for get the userID using the email
#
# + tokenEndpoint - token endpoint  
# + token - bearer token  
# + email - user email
# + return - return the user ID string
public isolated function searchUser(string tokenEndpoint, string token, string email) returns error|string {
    final http:Client clientEndpoint = check new (tokenEndpoint);
    json payload = {

        "schemas": [
            "urn:ietf:params:scim:api:messages:2.0:SearchRequest"
        ],
        "attributes": [

            "id"
        ],
        "filter": string `emails eq ${email}`,
        "domain": "DEFAULT",
        "startIndex": 1

    };
    string authHeader = string `Bearer ${token}`;
    http:Request tokenRequest = new;
    tokenRequest.setHeader("Authorization", authHeader);
    tokenRequest.setHeader("Content-Type", "application/scim+json");
    tokenRequest.setHeader("Accept", "application/scim+json");
    tokenRequest.setPayload(payload);
    model:scimSearchResponse resp = check clientEndpoint->post("/scim2/Users/.search", tokenRequest);
    io:println(resp);
    string userId = check resp.Resources[0].id;
    return userId;
}

# send patch request to update user role.
#
# + token - bearer token 
# + userId - userID get from the searchUser function
# + roleId - roleID get from the searchRole function
# + return - return the response from the asgardio
public isolated function updateRole(string token, string userId, string roleId) returns json|error {
    string tokenEndPonit = string `https://api.asgardeo.io/t/mediphix/scim2`;
    json payload = {
        "schemas": [
            "urn:ietf:params:scim:api:messages:2.0:PatchOp"
        ],
        "Operations": [

            {
                "op": "add",
                "path": "users",
                "value": [
                    {
                        "value": userId
                    }
                ]
            }

        ]
    };
    final http:Client clientEndpoint = check new (tokenEndPonit);
    string authHeader = string `Bearer ${token}`;
    http:Request tokenRequest = new;
    tokenRequest.setHeader("Authorization", authHeader);
    tokenRequest.setHeader("Content-Type", "application/scim+json");
    tokenRequest.setHeader("Accept", "application/scim+json");
    tokenRequest.setPayload(payload);
    string endPoint = string `/v2/Roles/${roleId}`;
    json resp = check clientEndpoint->patch(endPoint, tokenRequest);
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
            "schemas": [],
            "name": {
                "givenName": data.fname,
                "familyName": data.lname
            },
            "userName": "DEFAULT/" + data.email,
            "password": data.password,
            "emails": [
                {
                    "value": data.email,
                    "primary": true
                }
            ],
            "phoneNumbers": [
                {
                    "type": "mobile",
                    "value": data.mobile
                }
            ],
            "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
                "manager": {
                    "value": ""
                }
            },
            "urn:scim:wso2:schema": {
                "verifyEmail": false
            }
        };
        json|error? resp = addUser(endPoint, bToken, userData);
        if resp is error {
            mongodb:DeleteResult|mongodb:Error deleteOne = patientCollection->deleteOne(patient);
            if deleteOne is mongodb:DatabaseError {

                deleteOne = patientCollection->deleteOne(patient);
            }
            else {

                return resp;
            }
        }
        else {
            string userId = check searchUser(endPoint, bToken, data.email);
            json|error? roleUpdateResponse = updateRole(bToken, userId, patientRoleId);
            if roleUpdateResponse is error {
                mongodb:DeleteResult|mongodb:Error deleteOne = patientCollection->deleteOne(patient);
                if deleteOne is mongodb:DatabaseError {
                    deleteOne = patientCollection->deleteOne(patient);
                }
                else {

                    return deleteOne;
                }
            }
            else {
                return roleUpdateResponse;
            }
            io:println(roleUpdateResponse);

            return resp;
        }

    }
}

public function doctorRegistration(model:DoctorSignupData data) returns ()|error?|error {
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
        error? insertedDoctor = doctorCollection->insertOne(doctor);
        if (insertedDoctor is error) {
            mongodb:DeleteResult|mongodb:Error deletedUser = userCollection->deleteOne(doctorUser);
            mongodb:DeleteResult|mongodb:Error deletedDoctor = doctorCollection->deleteOne(doctor);
            return insertedDoctor;
        }
        else {
            string bToken = check fetchBeareToken(bearerTokenEndpoint, clientId, clientSecret);
            json userData = {
                "schemas": [],
                "name": {
                    "givenName": data.name

                },
                "userName": "DEFAULT/" + data.email,
                "password": data.password,
                "emails": [
                    {
                        "value": data.email,
                        "primary": true
                    }
                ],
                "phoneNumbers": [
                    {
                        "type": "mobile",
                        "value": data.mobile
                    }
                ],
                "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
                    "manager": {
                        "value": ""
                    }
                },
                "urn:scim:wso2:schema": {
                    "verifyEmail": false
                }
            };
            json|error? resp = addUser(endPoint, bToken, userData);
            if resp is error {
                mongodb:DeleteResult|mongodb:Error deletedUser = userCollection->deleteOne(doctorUser);
                mongodb:DeleteResult|mongodb:Error deletedDoctor = doctorCollection->deleteOne(doctor);
                return resp;
            }
            else {
                string userId = check searchUser(endPoint, bToken, data.email);
                json|error? roleUpdateResponse = updateRole(bToken, userId, doctorRoleId);
                if roleUpdateResponse is error {
                    mongodb:DeleteResult|mongodb:Error deletedUser = userCollection->deleteOne(doctorUser);
                    mongodb:DeleteResult|mongodb:Error deletedDoctor = doctorCollection->deleteOne(doctor);
                    return roleUpdateResponse;
                }
                else {
                    return ();
                }
                
            }
        }

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

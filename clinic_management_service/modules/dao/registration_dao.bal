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
configurable string AWS_REGION = ?;
configurable string S3_BUCKET_NAME = ?;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
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
    io:println("Inside addUser DAO"); // comment
    final http:Client clientEndpoint = check new (tokenEndpoint);
    string authHeader = string `Bearer ${token}`;
    http:Request tokenRequest = new;
    tokenRequest.setHeader("Authorization", authHeader);
    tokenRequest.setHeader("Content-Type", "application/scim+json");
    tokenRequest.setHeader("Accept", "application/scim+json");
    tokenRequest.setPayload(payload);
    io:println("Before token req in add user", tokenRequest); // comment
    json resp = check clientEndpoint->post("/scim2/Users", tokenRequest);

    io:println("Inside addUser DAO ........... END", resp); // comment
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
    io:println("Inside patientRegistrationDAO"); // comment
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    string emaiHead = getEmailHead(data.email);
    model:Patient patient = {
        mobile_number: data.mobile,
        first_name: data.fname,
        last_name: data.lname,
        birthday: data.dob,
        gender: data.gender,
        email: data.email,
        nic: data.nic,
        address: data.address,
        nationality: data.nationality,
        allergies: [],
        special_notes: [],
        doctors: [],
        medical_centers: [],
        appointments: [],
        medical_records: [],
        lab_reports: [],
        profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/patient-resources/" + emaiHead + "/profileImage"
    };
    mongodb:Error? insertOne = patientCollection->insertOne(patient);
    if insertOne is mongodb:DatabaseError {
        return insertOne;
    }
    //asgardio integration part 
    else {
        io:println("before bToken DAO..........."); //comment
        string bToken = check fetchBeareToken(bearerTokenEndpoint, clientId, clientSecret);
        io:println("after bToken DAO..........."); //comment

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
            io:println("Before user role adding DAO"); // comment
            string userId = check searchUser(endPoint, bToken, data.email);
            io:println("After user user ID fetch DAO"); // comment

            json|error? roleUpdateResponse = updateRole(bToken, userId, patientRoleId);
            io:println("Role Updated", roleUpdateResponse); // comment

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

public function getEmailHead(string email) returns string {
    string:RegExp emailHeadRegExp = re `@`;
    string[] emailChunks = emailHeadRegExp.split(email);
    string emailHead = string:'join("", ...emailChunks);
    return emailHead;
}

public function doctorRegistration(model:DoctorSignupData data) returns ()|error?|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");
    string emaiHead = getEmailHead(data.email);
    model:Doctor doctor = {
        name: data.name,
        slmc: data.slmc,
        nic: data.nic,
        education: data.education,
        mobile: data.mobile,
        specialization: data.specialization,
        email: data.email,
        category: [],
        availability: [],
        verified: false,
        patients: [],
        medical_centers: [],
        sessions: [],
        channellings: [],
        medical_records: [],
        lab_reports: [],
        profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/doctor-resources/" + emaiHead + "/profileImage",
        media_storage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/doctor-resources/" + emaiHead
    };
    model:User doctorUser = {
        email: data.email,
        role: "doctor"
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

public function registerMedicalCenter(model:MedicalCenterSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");
    mongodb:Collection MedicalCenterAdminCollection = check mediphixDb->getCollection("medical_center_admin");
    string emaiHead = getEmailHead(data.mcaData.email);
    string centerEmailHead = getEmailHead(data.mcData.email);

    model:User mcUser = {
        email: data.mcaData.email,
        role: "MCA"
    };

    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        map<json> filter = {"email": data.mcaData.email};
        map<json> projection = {
            "_id": {"$toString": "$_id"},
            "email": 1,
            "role": 1
        };
        model:User|mongodb:Error? createdUser = check userCollection->findOne(filter, {}, projection);
        if createdUser is mongodb:Error {
            return createdUser;
        }
        if (createdUser is model:User) {
            string? userId = createdUser._id;
            model:MedicalCenterAdmin MedicalCenterAdmin = {
                name: data.mcaData.name,
                nic: data.mcaData.nic,
                mobile: data.mcaData.mobile,
                profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/mca-resources/" + emaiHead + "/profileImage",
                medicalCenterEmail: data.mcData.email,
                userId: <string>userId
            };
            error? insertedMCA = check MedicalCenterAdminCollection->insertOne(MedicalCenterAdmin);
            if (insertedMCA is error) {
                return insertedMCA;
            }
            else {
                string bToken = check fetchBeareToken(bearerTokenEndpoint, clientId, clientSecret);
                json userData = {
                    "schemas": [],
                    "name": {
                        "givenName": data.mcaData.name

                    },
                    "userName": "DEFAULT/" + data.mcaData.email,
                    "password": data.mcaData.password,
                    "emails": [
                        {
                            "value": data.mcaData.email,
                            "primary": true
                        }
                    ],
                    "phoneNumbers": [
                        {
                            "type": "mobile",
                            "value": data.mcaData.mobile
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
                string RoleID = check searchRole(bToken, "Medical Center Admin");
                json|error? resp = addUser(endPoint, bToken, userData);
                if resp is error {
                    return resp;
                }
                else {
                    string addedUserId = check searchUser(endPoint, bToken, data.mcaData.email);
                    json|error? roleUpdateResponse = updateRole(bToken, addedUserId, RoleID);
                    if roleUpdateResponse is error {
                        return roleUpdateResponse;
                    }

                }

            }
        }

        //medical center registration
        model:MedicalCenter medicalCenter = {
            name: data.mcData.name,
            address: data.mcData.address,
            mobile: data.mcData.mobile,
            email: data.mcData.email,
            verified: false,
            district: data.mcData.district,
            specialNotes: data.mcData.specialNotes,
            profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/medical-center-resources/" + centerEmailHead + "/logo",
            appointmentCategories: [],
            doctors: [],
            appointments: [],
            patients: [],
            MedicalCenterStaff: []
        };
        error? insertedMC = check medicalCenterCollection->insertOne(medicalCenter);
        if (insertedMC is error) {
            return insertedMC;
        }
        else {
            return ();
        }

    }

}

public function registerMedicalCenterStaff(model:MedicalCenterStaffData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection MedicalCenterStaffCollection = check mediphixDb->getCollection("medical_center_staff");
    string emaiHead = getEmailHead(data.email);

    model:User mcUser = {
        email: data.email,
        role: "MCS"
    };

    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        map<json> filter = {"email": data.email};
        map<json> projection = {
            "_id": {"$toString": "$_id"},
            "email": 1,
            "role": 1
        };
        model:User|mongodb:Error? createdUser = check userCollection->findOne(filter, {}, projection);
        if createdUser is mongodb:Error {
            return createdUser;
        }
        if (createdUser is model:User) {
            string? userId = createdUser._id;
            model:MedicalCenterStaff MedicalCenterStaff = {
                name: data.name,
                nic: data.nic,
                mobile: data.mobile,
                profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/mcs-resources/" + emaiHead + "/profileImage",
                userId: <string>userId,
                empId: data.empId,
                centerId: data.centerId,
                assignedSessions: []
            };
            error? insertedMCS = check MedicalCenterStaffCollection->insertOne(MedicalCenterStaff);
            if (insertedMCS is error) {
                return insertedMCS;
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
                string RoleID = check searchRole(bToken, "Medical Center Staff");
                json|error? resp = addUser(endPoint, bToken, userData);
                if resp is error {
                    return resp;
                }
                else {
                    string addedUserId = check searchUser(endPoint, bToken, data.email);
                    json|error? roleUpdateResponse = updateRole(bToken, addedUserId, RoleID);
                    if roleUpdateResponse is error {
                        return roleUpdateResponse;
                    }
                    else {
                        return ();
                    }

                }

            }
        }

    }

}

public function registerMedicalCenterReceptionist(model:MedicalCenterReceptionistSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection MedicalCenterReceptionistCollection = check mediphixDb->getCollection("medical_center_receptionist");
    string emaiHead = getEmailHead(data.email);

    model:User mcUser = {
        email: data.email,
        role: "MCR"
    };

    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        map<json> filter = {"email": data.email};
        map<json> projection = {
            "_id": {"$toString": "$_id"},
            "email": 1,
            "role": 1
        };
        model:User|mongodb:Error? createdUser = check userCollection->findOne(filter, {}, projection);
        if createdUser is mongodb:Error {
            return createdUser;
        }
        if (createdUser is model:User) {
            string? userId = createdUser._id;
            model:MedicalCenterReceptionist MedicalCenterReceptionist = {
                name: data.name,
                nic: data.nic,
                mobile: data.mobile,
                profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/mcr-resources/" + emaiHead + "/profileImage",
                userId: <string>userId,
                empId: data.empId,
                centerId: data.centerId

            };
            error? insertedMCR = check MedicalCenterReceptionistCollection->insertOne(MedicalCenterReceptionist);
            if (insertedMCR is error) {
                return insertedMCR;
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
                string RoleID = check searchRole(bToken, "Medical Center Receptionist");
                json|error? resp = addUser(endPoint, bToken, userData);
                if resp is error {
                    return resp;
                }
                else {
                    string addedUserId = check searchUser(endPoint, bToken, data.email);
                    json|error? roleUpdateResponse = updateRole(bToken, addedUserId, RoleID);
                    if roleUpdateResponse is error {
                        return roleUpdateResponse;
                    }
                    else {
                        return ();
                    }

                }

            }
        }

    }

}

public function registerMedicalCenterLabStaff(model:MedicalCenterLabStaffSignupData data) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");
    mongodb:Collection MedicalCenterLabStaffCollection = check mediphixDb->getCollection("medical_center_lab_staff");
    string emaiHead = getEmailHead(data.email);

    model:User mcUser = {
        email: data.email,
        role: "MCLS"
    };

    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
    }
    else {
        map<json> filter = {"email": data.email};
        map<json> projection = {
            "_id": {"$toString": "$_id"},
            "email": 1,
            "role": 1
        };
        model:User|mongodb:Error? createdUser = check userCollection->findOne(filter, {}, projection);
        if createdUser is mongodb:Error {
            return createdUser;
        }
        if (createdUser is model:User) {
            string? userId = createdUser._id;
            model:MedicalCenterLabStaff MedicalCenterLabStaff = {
                name: data.name,
                nic: data.nic,
                mobile: data.mobile,
                profileImage: "https://" + S3_BUCKET_NAME + ".s3." + AWS_REGION + ".amazonaws.com/mcls-resources/" + emaiHead + "/profileImage",
                userId: <string>userId,
                empId: data.empId,
                centerId: data.centerId

            };
            error? insertedMCR = check MedicalCenterLabStaffCollection->insertOne(MedicalCenterLabStaff);
            if (insertedMCR is error) {
                return insertedMCR;
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
                string RoleID = check searchRole(bToken, "Medical Center Lab Staff");
                json|error? resp = addUser(endPoint, bToken, userData);
                if resp is error {
                    return resp;
                }
                else {
                    string addedUserId = check searchUser(endPoint, bToken, data.email);
                    json|error? roleUpdateResponse = updateRole(bToken, addedUserId, RoleID);
                    if roleUpdateResponse is error {
                        return roleUpdateResponse;
                    }
                    else {
                        return ();
                    }

                }

            }
        }

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
        role: "medical center"
    };
    error? insertedUser = check userCollection->insertOne(mcUser);
    if (insertedUser is error) {
        return insertedUser;
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
            mongodb:DeleteResult|mongodb:Error deletedUser = userCollection->deleteOne(mcUser);
            mongodb:DeleteResult|mongodb:Error deletedLab = laborataryCollection->deleteOne(lab);
            return resp;
        }
        else {
            string userId = check searchUser(endPoint, bToken, data.email);
            json|error? roleUpdateResponse = updateRole(bToken, userId, laborataryRoleId);
            if roleUpdateResponse is error {
                mongodb:DeleteResult|mongodb:Error deletedUser = userCollection->deleteOne(mcUser);
                mongodb:DeleteResult|mongodb:Error deletedLab = laborataryCollection->deleteOne(lab);
                return roleUpdateResponse;
            }
            else {
                return ();
            }

        }
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
    int|error? medicalCenterResult = medicalCEnterCollection->countDocuments(filter, {});

    if (userResult === 0 && medicalCenterResult === 0) {
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

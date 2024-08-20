import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/jwt;
import ballerina/time;
import ballerinax/redis;

// import ballerina/auth;

redis:Client redis = check new (
    connection = {
        host: "localhost",
        port: 6379
    }
);

// Endpoint for the clinic service
final http:Client clinicServiceEP = check new ("http://localhost:9090",
    retryConfig = {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    }
);

// Endpoint for the appointment service
final http:Client appointmentServiceEP = check new ("http://localhost:9091",
    retryConfig = {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    }
);

// JWT provider configurations
configurable string issuer = ?;
configurable string audience = ?;
configurable string jwksUrl = ?;

// Set default cache expiry time to 1 hour
int DEFAULT_CACHE_EXPIRY = 3600;

// Define the listner for the api gateway with port 9000
listener http:Listener httpListener = check new (9000);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
    ,
    auth: [
        {
            jwtValidatorConfig: {
                issuer: issuer,
                audience: audience,
                signatureConfig: {
                    jwksConfig: {
                        url: jwksUrl
                    }
                }
            },
            scopes: ["insert_appointment", "retrieve_own_patient_data", "check_patient"]
        }
    ]
}
service /patient on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["check_patient"]
        }
    }
    resource function get ispatient(http:Request req) returns http:Response|error? {
        string? authHeader = check req.getHeader("Authorization");
        if authHeader is string {
            string token = authHeader.substring(7);
            [jwt:Header, jwt:Payload] jwtInformation = check jwt:decode(token);
            json payload = jwtInformation[1].toJson();
            string userEmail = check payload.username;
            io:println("JWT username: ", userEmail);
            if userEmail is string {

                string? mobile = check redis->get(userEmail);
                if mobile is string {
                    io:println("This patient exists in cache: ", mobile);
                    http:Response|error? response = check clinicServiceEP->/patient/[mobile];
                    if (response !is http:Response) {
                        ErrorDetails errorDetails = {
                            message: "Internal server error",
                            details: "Error occurred while retrieving appointments",
                            timeStamp: time:utcNow()
                        };
                        InternalError internalError = {body: errorDetails};
                        http:Response errorResponse = new;
                        errorResponse.statusCode = 500;
                        errorResponse.setJsonPayload(internalError.body.toJson());
                        return errorResponse;
                    }
                    return response;
                } else {
                    log:printInfo("This patient does not exist in cache");
                    string mobileNumber = check clinicServiceEP->/patientMobileByEmail/[userEmail];
                    string stringResult = check redis->setEx(userEmail, mobileNumber, DEFAULT_CACHE_EXPIRY);
                    io:println("Cached: ", stringResult);
                    http:Response? response = check clinicServiceEP->/patient/[mobileNumber];
                    if (response !is http:Response) {
                        ErrorDetails errorDetails = {
                            message: "Internal server error",
                            details: "Error occurred while retrieving appointments",
                            timeStamp: time:utcNow()
                        };
                        InternalError internalError = {body: errorDetails};
                        http:Response errorResponse = new;
                        errorResponse.statusCode = 500;
                        errorResponse.setJsonPayload(internalError.body.toJson());
                        return errorResponse;
                    }
                    return response;
                }
            }
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while retrieving patient details",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    @http:ResourceConfig {
        // "insert_appointment" scope is required to invoke this resource
        auth: {
            scopes: ["insert_appointment"]
        }
    }
    resource function get appointments(string mobile) returns http:Response|error? {
        http:Response|error? response = check appointmentServiceEP->/appointments/[mobile];
        if (response !is http:Response) {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving appointments",
                timeStamp: time:utcNow()
            };
            InternalError internalError = {body: errorDetails};
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(internalError.body.toJson());
            return errorResponse;
        }
        return response;
    }

    resource function post appointment(NewAppointment newAppointment) returns http:Response|error? {
        http:Response|error? response = check appointmentServiceEP->/appointment.post(newAppointment);
        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while creating appointment",
            timeStamp: time:utcNow()
        };
        InternalError internalError = {body: errorDetails};
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(internalError.body.toJson());
        return errorResponse;
    }

}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    },
    auth: [
        {
            jwtValidatorConfig: {
                issuer: issuer,
                audience: audience,
                signatureConfig: {
                    jwksConfig: {
                        url: jwksUrl
                    }
                }
            },
            scopes: ["insert_appointment", "retrieve_own_patient_data"]
        }
    ]
}
service /doctor on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["insert_appointment", "retrieve_own_patient_data"]
        }
    }
    resource function get categorys/reserve(http:Request request) returns string|error? {
        io:println("Inside Appointment");
        json|http:ClientError patient = request.getJsonPayload();

        io:println("Patient: ", patient);

        return "Appointment Reserved Successfully";
    }

}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    },
    auth: [
        {
            jwtValidatorConfig: {
                issuer: issuer,
                audience: audience,
                signatureConfig: {
                    jwksConfig: {
                        url: jwksUrl
                    }
                }
            },
            scopes: ["update_appointment_status"]
        }
    ]
}
service /receptionist on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["update_appointment_status"]
        }
    }
    resource function put appointment/status(string mobile, int appointmentNumber, AppointmentStatus status) returns http:Response|error {
        http:Response|error response = check appointmentServiceEP->/appointment/status/[mobile]/[appointmentNumber]/[status];
        if response is http:Response {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while updating appointment status",
            timeStamp: time:utcNow()
        };

        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

}

// public function getPatientMobileByEmail(string userEmail) returns string|error? {
//     mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
//     mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
//     map<json> filter = {"email": userEmail};
//     Patient|error? findResults = check patientCollection->findOne(filter, {}, (), Patient);
//     if findResults !is Patient {
//         ErrorDetails errorDetails = {
//             message: string `Failed to find user with email ${userEmail}`,
//             details: string `patient/${userEmail}`,
//             timeStamp: time:utcNow()
//         };
//         NotFoundError userNotFound = {body: errorDetails};

//         return userNotFound;
//     }
//     return findResults;
// }

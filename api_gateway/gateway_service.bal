import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/log;
import ballerina/time;
import ballerinax/redis;

redis:Client redis = check new (
    connection = {
        host: "redis",
        port: 6379
    }
);

// Endpoint for the clinic service
final http:Client clinicServiceEP = check new ("http://clinic_management_service:9090",
    retryConfig = {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    }
);

// Endpoint for the appointment service
final http:Client appointmentServiceEP = check new ("http://appointment_management_service:9091",
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
    resource function get patientdata(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userMobile = check getCachedUserMobile(userEmail, userType);
            Patient patient = check getPatientData(userMobile);

            http:Response response = new;
            response.setJsonPayload(patient.toJson());
            response.statusCode = 200;
            return response;

        } on fail {
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
            scopes: ["insert_appointment", "retrieve_own_patient_data","retrive_appoinments"]
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

    @http:ResourceConfig {
        auth: {
            scopes: ["retrive_appoinments"]
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


    @http:ResourceConfig {
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }
    resource function get getSessionDetails(string mobile) returns http:Response|error? {
        http:Response|error? response = check clinicServiceEP->/getSessionDetails/[mobile];
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

public function getUserEmailByJWT(http:Request req) returns string|error {
    string authHeader = check req.getHeader("Authorization");
    string token = authHeader.substring(7);
    [jwt:Header, jwt:Payload] jwtInformation = check jwt:decode(token);
    json payload = jwtInformation[1].toJson();
    string userEmail = check payload.username;
    io:println("JWT username: ", userEmail);
    return userEmail;
}

public function getCachedUserMobile(string userEmail, string userType) returns string|error {
    string? mobile = check redis->get(userEmail);
    string userMobile = "";
    if mobile is string {
        io:println("This user exists in cache: ", mobile);
        userMobile = mobile;
    } else {
        log:printInfo("This user mobile does not exist in cache");
        string mobileNumber = "";
        if (userType == "patient") {
            mobileNumber = check clinicServiceEP->/patientMobileByEmail/[userEmail];

        } else if (userType == "doctor") {
            mobileNumber = check clinicServiceEP->/doctorMobileByEmail/[userEmail];
        }
        string stringResult = check redis->setEx(userEmail, mobileNumber, DEFAULT_CACHE_EXPIRY);
        io:println("Cached: ", stringResult);
        userMobile = mobileNumber;
    }
    if (userMobile == "") {
        return error("Error occurred while retrieving user mobile number");
    }
    return userMobile;
}

public function getPatientData(string mobile) returns Patient|error {
    Patient patient = check clinicServiceEP->/patient/[mobile];
    return patient;
}

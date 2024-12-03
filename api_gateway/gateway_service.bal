import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/log;
import ballerina/mime;
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
    resource function post register/patient(PatientSignupData data) returns http:Response|error? {
        http:Response|error? response = check clinicServiceEP->/signup/patient.post(data);

        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while registering patient",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    @http:ResourceConfig {
        auth: {
            scopes: ["check_patient"]
        }
    }
    resource function get patientdata(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userId = check getCachedUserId(userEmail, userType);
            Patient patient = check getPatientData(userId);

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
        auth: {
            scopes: ["insert_appointment"]
        }
    }
    resource function get appointments(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userId = check getCachedUserId(userEmail, userType);
            Appointment[] appointments = check getAppointments(userId) ?: [];

            http:Response response = new;
            response.setJsonPayload(appointments.toJson());
            response.statusCode = 200;
            return response;

        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving appointment details",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    resource function post appointment(http:Request request, NewAppointment newAppointment) returns http:Response|error? {
        io:println("Inside Appointment");
        newAppointment.patientId = check getCachedUserId(check getUserEmailByJWT(request), "patient");
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

            scopes: ["insert_appointment", "retrieve_own_patient_data", "retrive_appoinments", "submit_patient_records"]

        }
    ]
}
service /doctor on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["check_patient"]
        }
    }
    resource function get patientdata(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userId = check getCachedUserId(userEmail, userType);
            Patient patient = check getPatientData(userId);

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
    resource function get getSessionDetailsByDoctorId(http:Request req) returns http:Response|error? {
        string userEmail = check getUserEmailByJWT(req);
        string userType = "doctor";
        string userId = check getCachedUserId(userEmail, userType);
        http:Response|error? response = check clinicServiceEP->/getSessionDetailsByDoctorId/[userId];
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
    resource function post createSession(http:Request req ) returns http:Response|error? {
        string userEmail = check getUserEmailByJWT(req);
        string userType = "doctor";
        string userId = check getCachedUserId(userEmail, userType);
        http:Response|error? response = check clinicServiceEP->/getSessionDetailsByDoctorId/[userId];
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

    resource function get getDoctorName(string mobile) returns http:Response|error? {
        io:println("Inside getDoctorName in gateway");
        http:Response|error? doctorName = check clinicServiceEP->/getDoctorName/[mobile];
        return doctorName;
    }

    //get all medical centers
    @http:ResourceConfig {
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }
    resource function get getAllMedicalCenters() returns http:Response|error? {
        http:Response|error? response = check clinicServiceEP->/getAllMedicalCenters;
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
    resource function get getMyMedicalCenters(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
            http:Response|error? response = check clinicServiceEP->/getMyMedicalCenters/[userId];
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
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }

    resource function get getDoctorDetails(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
            http:Response|error? response = check clinicServiceEP->/getDoctorDetails/[userId];
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
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }
    resource function post setDoctorJoinRequest(http:Request req,MedicalCenterId id) returns error?|http:Response {
        do {

            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
           
            
           
            http:Response|error? response = check clinicServiceEP->/setDoctorJoinRequest/[userId]/[id.id].post(message = "");
            return  response;
            
            

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
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }
    resource function post doctor/registration(string mobile) returns http:Response|error? {
        // json|http:ClientError patient = request.getJsonPayload();
        io:println("Inside getDoctorName in gateway");
        http:Response|error? doctorName = check clinicServiceEP->/getDoctorName/[mobile];
        return doctorName;

    resource function post doctor/registration(DoctorSignupData data) returns http:Response|error? {
        io:println("Doctor data: ", data);
        http:Response|error? response = check clinicServiceEP->/signup/patient.post(data);

        if (response is http:Response) {
            return response;
        }

        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while registering doctor",
            timeStamp: time:utcNow()
        };

        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());

        return errorResponse;
    }

    resource function post upload/doctoridfront(http:Request request) returns http:Response|error? {
        io:println("Inside upload/doctoridfront in gateway");
        io:println("Payload", request.getJsonPayload());

        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({message: "Doctor ID front uploaded successfully"});
        return response;
        // string idFrontString = check clinicServiceEP->/upload/doctoridfront.post(idFront);
        // return idFrontString;

    }

    @http:ResourceConfig {
        auth: {
            scopes: ["submit_patient_records"]
        }
    }

    //submit patient medical record
    resource function post submitPatientRecord(PatientRecord patientRecord) returns http:Response|error? {
        http:Response|error? response = check clinicServiceEP->/submitPatientRecord.post(patientRecord);

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

    @http:ResourceConfig {
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }

    //get previous appointments details
    resource function get previousAppointments(http:Request req) returns http:Response|error? {
        do {
            string doctorEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string doctorId = check getCachedUserId(doctorEmail, userType);
            Appointment[] allAppointments = check getAppointmentsForDoctor(doctorId) ?: [];

            time:Utc currentTime = time:utcNow();
            Appointment[] previousAppointments = from Appointment appointment in allAppointments
                let time:Utc|error appointmentUtcResult = time:utcFromString(appointment.appointmentTime.toString())
                where appointmentUtcResult is time:Utc && appointmentUtcResult < currentTime
                select appointment;

            http:Response response = new;
            response.setJsonPayload(previousAppointments.toJson());
            response.statusCode = 200;
            return response;

        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving previous appointment details",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    //get upcoming appointments details
    resource function get upcomingAppointments(http:Request req) returns http:Response|error? {
        do {
            string doctorEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string doctorId = check getCachedUserId(doctorEmail, userType);
            Appointment[] allAppointments = check getAppointmentsForDoctor(doctorId) ?: [];
            io:println("Fetched all appointments: ", allAppointments.toString());

            time:Utc currentUtcTime = time:utcNow();

            Appointment[] upcomingAppointments = [];
            foreach Appointment appointment in allAppointments {
                string appointmentTimeStr = appointment.appointmentTime.toString();
                io:println("appointmentTimeStr: ", appointmentTimeStr);
                time:Utc parsedTime = check time:utcFromString(appointmentTimeStr);
                io:println("parsedTime: ", parsedTime);
                // Compare parsed appointment time with the current time
                if parsedTime > currentUtcTime {
                    upcomingAppointments.push(appointment);
                }
            }

            io:println("Filtered upcoming appointments: ", upcomingAppointments.toString());

            http:Response response = new;
            response.setJsonPayload(upcomingAppointments.toJson());
            response.statusCode = 200;
            return response;

        } on fail {

            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving upcoming appointment details",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
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
    io:println("JWT userEmail: ", userEmail);
    return userEmail;
}

public function getCachedUserId(string userEmail, string userType) returns string|error {
    string? objectId = check redis->get(userEmail);
    string userId = "";
    if objectId is string {
        io:println("This user exists in cache: ", objectId);
        userId = objectId;
    } else {
        log:printInfo("This user id does not exist in cache, lets retrieve from the DB");
        string id = "";
        if (userType == "patient") {
            id = check clinicServiceEP->/patientIdByEmail/[userEmail];

        } else if (userType == "doctor") {
            id = check clinicServiceEP->/doctorIdByEmail/[userEmail];
        }
        string stringResult = check redis->setEx(userEmail, id, DEFAULT_CACHE_EXPIRY);
        io:println("Cached: ", stringResult);
        userId = id;
    }
    if (userId == "") {
        return error("Error occurred while retrieving user mobile number");
    }
    return userId;
}

public function getPatientData(string userId) returns Patient|error {
    Patient patient = check clinicServiceEP->/patient/[userId];
    return patient;
}

public function getAppointments(string userId) returns Appointment[]|error? {
    Appointment[] appointments = check appointmentServiceEP->/appointments/[userId];
    return appointments;
}

public function getAppointmentsForDoctor(string userId) returns Appointment[]|error? {
    Appointment[] appointments = check appointmentServiceEP->/appointmentsByDoctorId/[userId];
    return appointments;
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /media on httpListener {
    resource function post upload(http:Request request, string email, string userType, string uploadType) returns http:Response|error? {
        mime:Entity[] formData = check request.getBodyParts();
        io:println("FormData: ", formData);
        byte[] fileBytes = [];
        string:RegExp emailValidator = re `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`;
        if !emailValidator.isFullMatch(email) {
            return error("Invalid email address");
        }
        string contentType = "";
        string fileName = "";

        foreach mime:Entity part in formData {
            if part.getContentDisposition().name == "file" {
                fileBytes = check part.getByteArray();
                contentType = part.getContentType();
                io:println("Decomposed: ", part.getContentDisposition());
                fileName = part.getContentDisposition().fileName;
            }
        }

        http:Response response = check clinicServiceEP->/uploadmedia/[userType]/[uploadType]/[email]/[fileName]/[contentType].post(fileBytes);

        return response;
    }

    resource function get images(http:Request request, string email, string userType, string uploadType) returns http:Response|error? {
        http:Response|error? response = check clinicServiceEP->/media/[userType]/[uploadType]/[email];
        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while retrieving images",
            timeStamp: time:utcNow()
        };
        InternalError internalError = {body: errorDetails};
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(internalError.body.toJson());
        return errorResponse;
        
    }

    resource function get imagelink(http:Request request, string userType, string uploadType) returns http:Response|error? {
        string email = check getUserEmailByJWT(request);
        http:Response|error? response = check clinicServiceEP->/medialink/[userType]/[uploadType]/[email];
        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while retrieving images",
            timeStamp: time:utcNow()
        };
        InternalError internalError = {body: errorDetails};
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(internalError.body.toJson());
        return errorResponse;
    }

}

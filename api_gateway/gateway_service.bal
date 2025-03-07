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
        io:println("Inside Gateway Service", data); // COMMENT
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

    resource function get doctordata() returns http:Response|error? {
        http:Response|error? response = check clinicServiceEP->/getAllDoctors;
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

    //    resource function get getDoctorName(string doctorId) returns http:Response|error? {
    //     io:println("Inside getDoctorName in gateway");
    //     http:Response|error? doctorName = check clinicServiceEP->/getDoctorName/[doctorId];
    //     return doctorName;
    // }

    resource function get centerdata() returns http:Response|error? {
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

    resource function get appointments(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userId = check getCachedUserId(userEmail, userType);
            AppointmentRecord[] appointments = check getAppointments(userId) ?: [];

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

    resource function get getUpcomingAppointments(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userId = check getCachedUserId(userEmail, userType);
            
            http:Response|error? response = check appointmentServiceEP->/getUpcomingAppointmentsByUserId/[userId];
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

    resource function get getPreviousAppointments(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "patient";
            string userId = check getCachedUserId(userEmail, userType);
            
            http:Response|error? response = check appointmentServiceEP->/getPreviousAppointmentsByUserId/[userId];
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
    resource function get getDoctorDetails/[string doctorId]() returns http:Response|error? {
        do {
            http:Response|error? response = check clinicServiceEP->/getDoctorDetails/[doctorId];
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

    resource function post appointment(NewAppointmentRecord newAppointmentRecord) returns http:Response|error {

        http:Response|error? response = check appointmentServiceEP->/createAppointmentRecord.post(newAppointmentRecord);

        if response is http:Response {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while creating session vacancy",
            timeStamp: time:utcNow()
        };

        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    resource function get appointment/[string doctorId]/sessiondetails(http:Request req) returns http:Response|error? {
        http:Response|error? response = check appointmentServiceEP->/getSessionDetailsByDoctorId/[doctorId]();
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

            scopes: ["update_own_doctor_sessions", "retrive_appoinments", "submit_patient_records", "basic_doctor"]
  
        }
    ]
}
service /doctor on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["basic_doctor"]
        }
    }
    resource function get medicalrecords(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
            http:Response response = check clinicServiceEP->/getMedicalRecordsByDoctorId/[userId];

            
            response.statusCode = 200;
            return response;

        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving doctor details",
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
            scopes: ["basic_doctor"]
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
            scopes: ["basic_doctor"]
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
                details: "Error occurred while retrieving medical centers",
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
                details: "Error occurred while retrieving medical center details",
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
    resource function get sessionVacancies(http:Request req) returns http:Response|error? {
        do {
            io:println("REQ recived");
            string userEmail = check getUserEmailByJWT(req);
            io:println("Got the email");
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
            io:println("Got userID, now directing to clinic mng service");
            http:Response|error? response = check clinicServiceEP->/getDoctorSessionVacancies/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving session vacancies",
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
    resource function post respondToSessionVacancy(http:Request req, NewDoctorResponse newDoctorResponse) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
            newDoctorResponse.doctorId = userId;

            http:Response|error? response = check clinicServiceEP->/respondDoctorToSessionVacancy.post(newDoctorResponse);
            if response is http:Response {
                return response;
            }
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while responding to session vacancy",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while responding to session vacancy",
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

    resource function get getDoctorDetails2(http:Request req) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);
            http:Response|error? response = check clinicServiceEP->/getDoctorDetails2/[userId];
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
    resource function post setDoctorJoinRequest(http:Request req, MedicalCenterId id) returns error?|http:Response {
        do {

            string userEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string userId = check getCachedUserId(userEmail, userType);

            http:Response|error? response = check clinicServiceEP->/setDoctorJoinRequest/[userId]/[id.id].post(message = "");
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
            scopes: ["retrive_appoinments"]
        }
    }

    resource function patch appointments/[int aptNumber]/medicalRecord(http:Request request)
    returns http:Response|error {

        json|http:ClientError jsonPayload = request.getJsonPayload();

        if jsonPayload is http:ClientError {
            ErrorDetails errorDetails = {
                message: "Invalid JSON payload",
                details: jsonPayload.message(),
                timeStamp: time:utcNow()
            };
            return createResponse(400, errorDetails);
        }

        NewMedicalRecord|error tempRecord = jsonPayload.fromJsonWithType(NewMedicalRecord);
        if tempRecord is error {
            ErrorDetails errorDetails = {
                message: "Invalid medical record format",
                details: tempRecord.message(),
                timeStamp: time:utcNow()
            };
            return createResponse(400, errorDetails);
        }
        http:Response|error? response = check appointmentServiceEP->/appointments/[aptNumber]/medicalRecord.patch(tempRecord);

        if (response is http:Response) {
            return response;
        }

        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while updating medical record",
            timeStamp: time:utcNow()
        };
        return createResponse(500, errorDetails);
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
            AppointmentRecord[] allAppointments = check getAppointments(doctorId) ?: [];

            time:Utc currentTime = time:utcNow();
            AppointmentRecord[] previousAppointments = from AppointmentRecord appointment in allAppointments
                let time:Utc|error appointmentUtcResult = time:utcFromString(appointment.aptCreatedTimestamp.toString())
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
    @http:ResourceConfig {
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }

    resource function get upcomingAppointments(http:Request req) returns http:Response|error? {
        do {
            string doctorEmail = check getUserEmailByJWT(req);
            string userType = "doctor";
            string doctorId = check getCachedUserId(doctorEmail, userType);
            AppointmentRecord[] allAppointments = check getAppointments(doctorId) ?: [];
            io:println("Fetched all appointments: ", allAppointments.toString());

            time:Utc currentUtcTime = time:utcNow();

            AppointmentRecord[] upcomingAppointments = [];
            foreach AppointmentRecord appointment in allAppointments {
                string appointmentTimeStr = appointment.aptCreatedTimestamp.toString();
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

    @http:ResourceConfig {
        auth: {
            scopes: ["retrive_appoinments"]
        }
    }

    resource function get getAptDetailsForOngoingSessions/[int refNumber](http:Request req) returns http:Response|error? {
    
         http:Response|error? response = check clinicServiceEP->/getAptDetailsForOngoingSessions/[refNumber]();
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

    resource function get getSessionDetailsForDoctorHome(http:Request req) returns http:Response|error? {
        string doctorEmail = check getUserEmailByJWT(req);
        string userType = "doctor";
        string doctorId = check getCachedUserId(doctorEmail, userType);
        http:Response|error? response = check appointmentServiceEP->/getSessionDetailsByDoctorId/[doctorId]();
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
    resource function get getOngoingSessionQueue(http:Request req) returns http:Response|error? {
        string userEmail = check getUserEmailByJWT(req);
        string userType = "doctor";
        string userId = check getCachedUserId(userEmail, userType);
    
         http:Response|error? response = check clinicServiceEP->/getOngoingSessionQueue/[userId]();
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
    resource function get getPatientDetailsForOngoingSessions/[int refNumber](http:Request req) returns http:Response|error? {
         http:Response|error? response = check clinicServiceEP->/getPatientDetailsForOngoingSessions/[refNumber]();
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
            scopes: ["check_patient"]
        }
    ]
}
service /receptionist on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["check_patient"]
        }
    }
    resource function get receptionistdata(http:Request request) returns http:Response|error? {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userType = "receptionist";
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
            scopes: ["check_patient"]
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

// MCS [START] .......................................................................................
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /mcs on httpListener {

    @http:ResourceConfig
    resource function get upcomingClinicSessions(http:Request request) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            http:Response response = check clinicServiceEP->/mcsUpcomingClinicSessions/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function get ongoingClinicSessions(http:Request request) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            http:Response response = check clinicServiceEP->/mcsOngoingClinicSessions/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function get ongoingClinicSessions/[string sessionId](http:Request request) returns http:Response {
        do {
            http:Response response = check clinicServiceEP->/mcsOngoingClinicSessionTimeSlots/[sessionId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig

    resource function put startAppointment(http:Request request, string sessionId, int slotId) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsStartAppointment?sessionId=${sessionId}&slotId=${slotId}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put startTimeSlot(http:Request request, string sessionId) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsStartTimeSlot?sessionId=${sessionId}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put endTimeSlot(http:Request request, string sessionId) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsEndTimeSlot?sessionId=${sessionId}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put endLastTimeSlot(http:Request request, string sessionId) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsEndLastTimeSlot?sessionId=${sessionId}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put moveToAbsent(http:Request request, string sessionId, int slotId, int aptNumber) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsMoveToAbsent?sessionId=${sessionId}&slotId=${slotId}&aptNumber=${aptNumber}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put revertFromAbsent(http:Request request, string sessionId, int slotId, int aptNumber) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsRevertFromAbsent?sessionId=${sessionId}&slotId=${slotId}&aptNumber=${aptNumber}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put addToEnd(http:Request request, string sessionId, int slotId, int aptNumber) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcs");

            string url = string `/mcsAddToEnd?sessionId=${sessionId}&slotId=${slotId}&aptNumber=${aptNumber}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }
}

// MCS [END] .......................................................................................

// MCR [START] .......................................................................................
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /mcr on httpListener {

    @http:ResourceConfig
    resource function get searchPayment/[int aptNumber](http:Request request) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcr");

            http:Response response = check clinicServiceEP->/mcrSearchPayment/[aptNumber]/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put markToPay(http:Request request, int aptNumber) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mcr");
            string url = string `/mcrMarkToPay?aptNumber=${aptNumber}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

}

// MCR [END] .......................................................................................

// ROLE [START] .......................................................................................
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
            }
        }
    ]
}
service /user on httpListener {

    @http:ResourceConfig
    resource function get find(http:Request request) returns http:Response {
        do {
            string userEmail = check getUserEmailByJWT(request);

            http:Response response = check clinicServiceEP->/findUserRole/[userEmail];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }
}

// ROLE [END] .......................................................................................

/// Registration Listener...........................................................................
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /registration on httpListener {

     resource function post doctor/registration(DoctorSignupData data) returns http:Response|error? {
        io:println("Doctor data: ", data);
        http:Response|error? response = check clinicServiceEP->/signup/doctor.post(data);

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

    resource function post medicalCenter(MedicalCenterSignupData data) returns http:Response|error? {
        io:println("Inside Gateway Service", data); // COMMENT
        http:Response|error? response = check clinicServiceEP->/signup/medicalCenter.post(data);

        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while registering medical center",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    resource function post medicalCenterStaff(MedicalCenterStaffSignupData data) returns http:Response|error? {
        io:println("Inside Gateway Service", data); // COMMENT
        http:Response|error? response = check clinicServiceEP->/signup/MedicalCenterStaff.post(data);

        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while registering medical center Staff",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    resource function post registerMedicalCenterReceptionist(MedicalCenterReceptionistSignupData data) returns http:Response|error? {
        io:println("Inside Gateway Service", data); // COMMENT
        http:Response|error? response = check clinicServiceEP->/signup/registerMedicalCenterReceptionist.post(data);

        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while registering medical center Receptionist",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    resource function post registerMedicalCenterLabStaff(MedicalCenterLabStaffSignupData data) returns http:Response|error? {

        http:Response|error? response = check clinicServiceEP->/signup/registerMedicalCenterLabStaff.post(data);

        if (response is http:Response) {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while registering medical center Lab Staff",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }
}

//Medical center admin
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /mca on httpListener {


    @http:ResourceConfig
    resource function get joinRequests(http:Request request) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mca");

            http:Response response = check clinicServiceEP->/mcaJoinReq/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function put acceptRequest(http:Request request, string reqId) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mca");

            string url = string `/mcaAcceptRequest?reqId=${reqId}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }


    @http:ResourceConfig
    resource function get getOngoingSessionQueue(http:Request req) returns http:Response|error? {
        string userEmail = check getUserEmailByJWT(req);
        string userType = "doctor";
        string userId = check getCachedUserId(userEmail, userType);
    
         http:Response|error? response = check clinicServiceEP->/getOngoingSessionQueue/[userId]();
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

     @http:ResourceConfig
    resource function get getPatientDetailsForOngoingSessions/[int refNumber](http:Request req) returns http:Response|error? {
         http:Response|error? response = check clinicServiceEP->/getPatientDetailsForOngoingSessions/[refNumber]();
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

     
    @http:ResourceConfig
    resource function get MCSdata(http:Request request) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mca");

            http:Response response = check clinicServiceEP->/mcaGetMCSdata/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

      @http:ResourceConfig
    resource function get activeSessions(http:Request request) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mca");

            http:Response response = check clinicServiceEP->/mcsGetActiveSessions/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    // change here
    @http:ResourceConfig
    resource function put assign(http:Request request, string sessionId, string mcsId) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mca");

            string url = string `/mcaAssignSession?sessionId=${sessionId}&mcsId=${mcsId}&userId=${userId}`;

            http:Response response = check clinicServiceEP->put(url, {});
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }

    @http:ResourceConfig
    resource function get MCRdata(http:Request request) returns http:Response {
        do {
            // TODO :: get the {userEmail} from JWT
            string userEmail = check getUserEmailByJWT(request);
            string userId = check getCachedUserId(userEmail, "mca");

            http:Response response = check clinicServiceEP->/mcaGetMCRdata/[userId];
            return response;
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }
    }


    @http:ResourceConfig
    resource function post createSessionVacancy(NewSessionVacancy newSessionVacancy) returns http:Response|error {

        http:Response|error? response = check clinicServiceEP->/createSessionVacancy.post(newSessionVacancy);

        if response is http:Response {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while creating session vacancy",
            timeStamp: time:utcNow()
        };

        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

    resource function get getMcaSessionVacancies(http:Request req) returns error|http:Response {
        do {
            string userEmail = check getUserEmailByJWT(req);
            string userType = "mca";
            string userId = check getCachedUserId(userEmail, userType);
            http:Response|error? response = check clinicServiceEP->/getMcaSessionVacancies/[userId];
            if response is http:Response {
                return response;
            } else {
                ErrorDetails errorDetails = {
                    message: "Internal server error",
                    details: "Error occurred while retrieving session vacancies",
                    timeStamp: time:utcNow()
                };
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setJsonPayload(errorDetails.toJson());
                return errorResponse;
            }
        } on fail {
            ErrorDetails errorDetails = {
                message: "Internal server error",
                details: "Error occurred while retrieving mca session vacancies",
                timeStamp: time:utcNow()
            };
            http:Response errorResponse = new;
            errorResponse.statusCode = 500;
            errorResponse.setJsonPayload(errorDetails.toJson());
            return errorResponse;
        }

    }

    resource function patch acceptDoctorResponseApplicationToOpenSession/[string sessionVacancyId]/[int responseId]/[int appliedOpenSessionId](http:Request request, SessionCreationDetails sessionCreationDetails) returns http:Response|error {
        string userEmail = check getUserEmailByJWT(request);
        string userType = "mca";
        string userId = check getCachedUserId(userEmail, userType);

        http:Response|error? response = check clinicServiceEP->/mcaAcceptDoctorResponseApplicationToOpenSession/[userId]/[sessionVacancyId]/[responseId]/[appliedOpenSessionId].patch(sessionCreationDetails);
        if response is http:Response {
            return response;
        }
        ErrorDetails errorDetails = {
            message: "Internal server error",
            details: "Error occurred while accepting doctor response to open session",
            timeStamp: time:utcNow()
        };
        http:Response errorResponse = new;
        errorResponse.statusCode = 500;
        errorResponse.setJsonPayload(errorDetails.toJson());
        return errorResponse;
    }

}

public function getUserEmailByJWT(http:Request req) returns string|error {
    io:println("Inside getUserEmailByJWT");
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
        } else if (userType == "mcs") {
            id = check clinicServiceEP->/mcsIdByEmail/[userEmail];
        } else if (userType == "mcr") {
            id = check clinicServiceEP->/mcrIdByEmail/[userEmail];
        } else if (userType == "mca") {
            id = check clinicServiceEP->/mcaIdByEmail/[userEmail];
        }
        string stringResult = check redis->setEx(userEmail, id, DEFAULT_CACHE_EXPIRY);
        io:println("Cached: ", stringResult);
        userId = id;
    }
    if (userId == "") {
        return error("Error occurred while retrieving user id");
    }
    return userId;
}

public function getPatientData(string userId) returns Patient|error {
    Patient patient = check clinicServiceEP->/patient/[userId];
    return patient;
}

public function getAppointments(string userId) returns AppointmentRecord[]|error? {
    AppointmentRecord[] appointments = check appointmentServiceEP->/appointments/[userId];
    return appointments;
}

// Helper function to create consistent responses
public function createResponse(int statusCode, ErrorDetails payload) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload(payload.toJson());
    return response;
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


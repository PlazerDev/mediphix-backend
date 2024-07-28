import clinic_management_service.'service;
import clinic_management_service.model;

import ballerina/http;
import ballerina/io;

type Doctor record {
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
};

// type Patient record {
//     string name;
//     string dob;
//     string address;
//     string phone;
//     string email;
// };

type ReservationStatus record {
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID;
    string status;
};

function addCORSHeaders(http:Response response) {
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS, DELETE, PUT");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");
}


@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]

    }
}


service / on new http:Listener(9090) {

    // patient

    // Handle preflight request
    resource function options signup(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        addCORSHeaders(response);
        check caller->respond(response);
    }

    //Registration Part
    resource function post signup/patient(model:PatientSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is signup");

        model:ReturnMsg result = 'service:registerPatient(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Patient Registered Successfully"});
        }

        addCORSHeaders(response);
        io:println(result);
        return (response);

    }

    resource function post signup/doctor(model:DoctorSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is doctor");
        

        model:ReturnMsg result =   'service:registerDoctor(data)  ;


        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Doctor Registered Successfully"});
        }


        io:println(result);
        addCORSHeaders(response);
        return (response);

    }

    resource function post signup/medicalcenter(model:otherSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Medical Center");
        

        model:ReturnMsg result =   'service:registerMedicalCenter(data) ;


        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Medical Center Registered Successfully"});
        }


        io:println(result);
        addCORSHeaders(response);
        return (response);

    }

    resource function post signup/laboratary(model:otherSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Laboratary");
        

        model:ReturnMsg result =   'service:registerLaboratary(data) ;


        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Laboratary Registered Successfully"});
        }


        io:println(result);
        addCORSHeaders(response);
        return (response);

    }



    // Handle preflight request
    resource function options patient(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        addCORSHeaders(response);
        check caller->respond(response);
    }

    // Get patient with mobile number
    resource function get patient(string mobile) returns http:Response|error? {
        model:Patient|model:ValueError|model:UserNotFound|model:InternalError patient = 'service:getPatient(mobile.trim());

        http:Response response = new;
        if patient is model:Patient {
            response.statusCode = 200;
            response.setJsonPayload(patient.toJson());
        } else if patient is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(patient.body.toJson());
        } else if patient is model:UserNotFound {
            response.statusCode = 404;
            response.setJsonPayload(patient.body.toJson());
        } else if patient is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(patient.body.toJson());
        }
        addCORSHeaders(response);
        return response;
    }


}


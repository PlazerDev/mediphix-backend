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

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]

    }
}
service / on new http:Listener(9090) {

    // patient

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

        io:println(result);
        return (response);

    }

    resource function post signup/doctor(model:DoctorSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is doctor");

        model:ReturnMsg result = 'service:registerDoctor(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Doctor Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/medicalcenter(model:otherSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Medical Center");

        model:ReturnMsg result = 'service:registerMedicalCenter(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Medical Center Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/laboratary(model:otherSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Laboratary");

        model:ReturnMsg result = 'service:registerLaboratary(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Laboratary Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    // Get patient with user id
    resource function get patient/[string userId]() returns http:Response|error? {
        model:Patient|model:ValueError|model:NotFoundError|model:InternalError patient = 'service:getPatientById(userId.trim());
        http:Response response = new;
        if patient is model:Patient {
            response.statusCode = 200;
            response.setJsonPayload(patient.toJson());
        } else if patient is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(patient.body.toJson());
        } else if patient is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(patient.body.toJson());
        } else if patient is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(patient.body.toJson());
        }
        return response;
    }

    // Get patient with email
    resource function get patientIdByEmail/[string email]() returns string|error? {
        model:Patient|model:ValueError|model:NotFoundError|model:InternalError patient = 'service:getPatientByEmail(email.trim());
        if patient is model:Patient {
            return patient._id;
        } else {
            return error("Error occurred while retrieving patient id number");
        }
    }

    // Get appointments of a patient
    resource function get appointments(string mobile) returns http:Response|error {
        model:Appointment[]|model:ReturnResponse appointments = check 'service:getAppointments(mobile);

        http:Response response = new;
        if appointments is model:Appointment[] {
            response.statusCode = 200;
            response.setJsonPayload(appointments.toJson());
        } else if appointments is model:ReturnResponse {
            response.statusCode = appointments.statusCode;
            response.setJsonPayload(appointments.toJson());
        }
        io:println(appointments);
        return response;
    }

    //Doctor Colnrollers ......................................................................................................................

    resource function get getSessionDetails/[string mobile]() returns http:Response|error?{
        model:Sessions[]|model:InternalError session = check 'service:getSessionDetails(mobile.trim());
        
        http:Response response = new;
        if session is model:Sessions[] {
            response.statusCode = 200;
            response.setJsonPayload(session.toJson());
            io:println("Function responde successfully");
        } else if session is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(session.body.toJson());
        }
        return response;

    }


    // Get doctor name by mobile  .................V..............................................
    resource function get getDoctorName/[string mobile]() returns error|http:Response {
        string|model:InternalError doctorName =  check 'service:getDoctorName(mobile.trim());

        io:println(doctorName);
        http:Response response = new;
        if (doctorName is string) {
            response.statusCode = 200;
            response.setJsonPayload({doctorName: doctorName});
        } else {
            response.statusCode = 404;
            response.setJsonPayload({message: "Doctor not found"});
        }
        return response;
    }

    //submit patient record
    resource function post submitPatientRecord(model:PatientRecord patientRecord) returns http:Response|error {
    http:Created|model:InternalError patientRecordSubmissionStatus = check 'service:submitPatientRecord(patientRecord);
    http:Response response = new;

    if (patientRecordSubmissionStatus is http:Created) {
        response.statusCode = 201;
        response.setJsonPayload({message: "Patient record submitted successfully"});
        return response;
    } 
    else if (patientRecordSubmissionStatus is model:InternalError) {
        response.statusCode = 500;
        response.setJsonPayload(patientRecordSubmissionStatus.body.toJson());
    }

    return response;
}


    // medical center staff controllers .......................................................................................

    // return initial informtion of a medical center staff member by userId
    resource function get mcsMember(string userId) returns http:Response|error? {

        model:MCSwithMedicalCenter|model:NotFoundError|model:InternalError result = 'service:getMCSMemberInformationService(userId.trim());
        http:Response response = new;
        if result is model:MCSwithMedicalCenter {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if result is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        } else if result is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        }
        return response;

    }

}


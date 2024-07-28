import clinic_management_service.'service;
import clinic_management_service.dao;
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

service / on new http:Listener(9090) {

    resource function get patient/appointments(string id) returns http:Response|error? {
        io:println("Hello this is patient appointments.");
        // Patient patient = {
        //     mobile_number: "0787654329",
        //     first_name: "Kasun",
        //     last_name: "Ranathunga",
        //     nic: "987654321V",
        //     birthday: "1999-05-15",
        //     email: "kavindirana@gmail.com",
        //     address: {
        //         house_number: "56/7",
        //         street: "Temple Road",
        //         city: "Mount Lavinia",
        //         province: "Western",
        //         postal_code: "10370"
        //     },
        //     allergies: ["Pollen", "Dust"],
        //     special_notes: ["Requires follow-up on previous condition", "Has a history of asthma"]
        // };
        return;
    }

    resource function post patient/registration(model:Patient patient) returns http:Response|error? {
        error? savepatientResult = dao:savePatient(patient);
        if savepatientResult is error {

        }

        http:Response response = new;

        return response;
    }

    resource function post [string hospital_id]/categorys/[string category]/reserve() returns model:Appointment|http:ClientError|error? {
        io:println("Hello this is reservation thing");
        return;
    }

    resource function post healthcare/payments() returns ReservationStatus|http:ClientError|error? {
        io:println("Hello this is hospital id with category");
        return;
    }

    resource function get [string hospital_id]/categories/appointments/[int appointmentNumber]/fee() returns ReservationStatus|http:ClientError|error? {
        io:println("Hello this fee section");
        return;
    }

    resource function options signup(http:Caller caller, http:Request req) returns error? {
        // Handle preflight request
        http:Response response = new;

        addCORSHeaders(response);
        check caller->respond(response);
    }

    //Registration Part
    resource function post signup(model:PatientSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is signup");
        

        error? result =  check 'service:patientRegistrationService(data)  ;

        http:Response response = new;
        model:ReturnMsg returnMsg={message: "", status: 0};
        if (result is error) {
            response.statusCode = 500;
            response.setJsonPayload({message: result.message()});
            returnMsg.message = result.message();
            returnMsg.status = 500;
 
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Patient Registered Successfully"});
            returnMsg.message = "Patient Registered Successfully";
            returnMsg.status = 200;

        }

        addCORSHeaders(response);
        io:println(result);
        return (response);         

    }


    // medical center staff controllers .......................................................................................

    // return initial informtion of a medical center staff member by userId
    resource function get mcsMember(string userId) returns http:Response|error? {

        model:MCS|model:NotFoundError|model:InternalError result = 'service:getMCSMemberInformationService(userId.trim());
        http:Response response = new;
        if result is model:MCS {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if result is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        } else if result is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        }
        addCORSHeaders(response);
        return response;

    }
}


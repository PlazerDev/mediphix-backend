import ballerina/http;
import ballerina/io;

type Doctor record {
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
};

type Patient record {
    string name;
    string dob;
    string address;
    string phone;
    string email;
};

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

type Appointment record {
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean paid;
    string appointmentDate;
};

service / on new http:Listener(9090) {

    resource function get patient/appointments(string id) returns http:Response|error? {
        io:println("Hello this is patient appointments.");

        return;
    }

    resource function post patient/registration(string id) returns http:Response|error? {
        io:println("Hello this is patient registration.");

        return;
    }

    resource function post [string hospital_id]/categorys/[string category]/reserve() returns Appointment|http:ClientError|error? {
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

}


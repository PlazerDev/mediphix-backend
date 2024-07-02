import ballerina/http;

type Doctor record {
    string name;
    string hospital;
    string specialization;
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

type Appointment record {
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean paid;
    string appointmentDate;
};

type PatientWithCardNo record {
    *Patient;
    string cardNo;
};

type ReservationRequest record {
    PatientWithCardNo patient;
    string doctor;
    string hospital_id;
    string hospital;
    string appointment_date;
};

type Fee record {
    string patientName;
    string doctorName;
    string actualFee;
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

service /mediphix on new http:Listener(9090) {
    resource function post specializations/[string specialization]/book(ReservationRequest payload) returns ReservationStatus|http:NotFound|http:InternalServerError {
    }

}

configurable string appointmentManagementService = "http://localhost:9001";
configurable string paymentManagementService = "http://localhost:9002";

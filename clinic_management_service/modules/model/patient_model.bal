// import ballerina/time;
import ballerina/time;

public type PatientWithCardNo record {
    *Patient;
    string cardNo;
};

public type Address record {|
    string house_number;
    string street;
    string city;
    string province;
    string postal_code;
|};




public type Appointment record {|
    int appointmentNumber;
    string doctorEmail;
    string patientMobile;
    int doctorSessionId;
    int category;
    string hospital;
    boolean paid;
    AppointmentStatus status;
    string appointmentDate;
    string appointmentTime;
    time:Date createdTime;
    time:Date lastModifiedTime;
|};


public enum AppointmentStatus {
    ACTIVE,
    PAID,
    INQUEUE,
    ONGOING,
    OVER,
    CANCELLED
};
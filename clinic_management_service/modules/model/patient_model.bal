// import ballerina/time;
import ballerina/time;

public type Patient record {|
    string _id;
    string mobile_number;
    string first_name;
    string last_name;
    string nic;
    string birthday;
    string email;
    string address;
    string nationality;
    string[] allergies?;
    string[] special_notes?;
    string[] doctors?;
    string[] medical_centers?;
    string[] appointments?;
    string[] medical_records?;
    string[] lab_reports?;
|};

public type UnregisteredPatient record {|
    string mobile_number;
    string first_name;
    string last_name;
    string nic;
    string birthday;
    string email;
    string address;
    string nationality;
    string[] allergies?;
    string[] special_notes?;
    string[] doctors?;
    string[] medical_centers?;
    string[] appointments?;
    string[] medical_records?;
    string[] lab_reports?;
|};

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

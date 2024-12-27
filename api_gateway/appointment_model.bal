import ballerina/time;

public enum AppointmentStatus {
    ACTIVE,
    PAID,
    INQUEUE,
    ONGOING,
    OVER,
    CANCELLED
};

public enum AppointmentCategory {
    GENERAL_MEDICINE,
    CARDIOLOGY,
    ORTHOPEDICS,
    PEDIATRICS,
    GYNECOLOGY_OBSTETRICS,
    DERMATOLOGY,
    ENT,
    NEUROLOGY,
    GASTROENTEROLOGY,
    PULMONOLOGY,
    ONCOLOGY,
    ENDOCRINOLOGY,
    NEPHROLOGY,
    UROLOGY,
    PSYCHIATRY_MENTAL_HEALTH,
    OPHTHALMOLOGY,
    DENTISTRY,
    PHYSICAL_THERAPY_REHABILITATION,
    ALLERGY_IMMUNOLOGY,
    RADIOLOGY,
    GERIATRICS,
    EMERGENCY_MEDICINE,
    OCCUPATIONAL_HEALTH
};

public type NewAppointment record {
    string doctorId;
    string patientId?;
    string sessionId;
    string category;
    string medicalCenterId;
    string medicalCenterName;
    boolean isPaid;
    decimal payment;
    AppointmentStatus status;
    string appointmentTime;  // accepted format -> 2024-10-03T10:15:30.00Z
};

public type Appointment record {|
    string _id?;
    int appointmentNumber;
    string doctorId;
    string patientId;
    string sessionId;
    string medicalRecordId?;
    string category;
    string medicalCenterId;
    string medicalCenterName;
    boolean isPaid;
    decimal payment;
    AppointmentStatus status;
    time:Date appointmentTime;
    time:Date createdTime;
    time:Date lastModifiedTime;
|};


public type Counter record {
    string _id;
    int sequenceValue;
};

public  type Session record {
    int sessionNumber;
    string medicalCenterName;
    string doctorEmail;
    string hospital;
    string appointmentDate;
    string appointmentTime;
    AppointmentCategory category;
    string medicalCenterMobile;
};

//new appointment record for reviva
public type AppointmentRecord record {
    string _id;
    int apt_Number;
    string session_id;
    int time_slot;
    time:Date apt_created_timestamp;
    AppointmentStatus apt_status;
    string patient;
    boolean is_paid;
    int queue_number;
    MedicalRecord medical_record;
};

public type MedicalRecord record {
    int apt_Number;
    time:Date started_timestamp;
    time:Date ended_timestamp;
    string[] symptoms;
    Diagnosis diagnosis;
    Treatment treatments;
    string note_to_patient?;
    boolean is_lab_report_required;
    LabReport? lab_report;
};

public type LabReport record {
    time:Date requested_timestamp;
    boolean is_high_prioritize;
    string test_type;
    string test_name;
    string note_to_lab_staff;
    int status;
    ReportDetails report_details;
};

public type ReportDetails record {  
    time:Date test_started_timestamp;
    time:Date test_ended_timestamp; 
    string? additional_note;
    string[]? result_files;
};

public type Treatment record {
    string[] medications;
    string[] description;    
};

public type Diagnosis record {
    string[] category;
    string[] description;
};

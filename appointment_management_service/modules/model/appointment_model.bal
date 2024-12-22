import ballerina/time;

public enum AppointmentStatus {
    ACTIVE,
    PAID,
    INQUEUE,
    ONGOING,
    OVER,
    LATE,
    ABSENT,
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

// public enum AppointmentCategory {
//     PRIMARY_CARE_GENERAL_MEDICINE,
//     PRIMARY_CARE_PEDIATRICS,

//     SPECIALTY_CARE_CARDIOLOGY,
//     SPECIALTY_CARE_ORTHOPEDICS,
//     SPECIALTY_CARE_NEUROLOGY,
//     SPECIALTY_CARE_PULMONOLOGY,
//     SPECIALTY_CARE_GASTROENTEROLOGY,
//     SPECIALTY_CARE_ENDOCRINOLOGY,
//     SPECIALTY_CARE_NEPHROLOGY,
//     SPECIALTY_CARE_UROLOGY,
//     SPECIALTY_CARE_ONCOLOGY,
//     SPECIALTY_CARE_DERMATOLOGY,

//     WOMENS_HEALTH_GYNECOLOGY_OBSTETRICS,

//     MENTAL_HEALTH_PSYCHIATRY,
//     MENTAL_HEALTH_PSYCHOLOGY,

//     SURGICAL_CARE_GENERAL_SURGERY,
//     SURGICAL_CARE_SPECIALIZED_SURGERY,
//     SURGICAL_CARE_PLASTIC_RECONSTRUCTIVE_SURGERY,

//     DIAGNOSTICS_IMAGING_RADIOLOGY,
//     DIAGNOSTICS_IMAGING_LABORATORY_MEDICINE,

//     EMERGENCY_ACUTE_CARE_EMERGENCY_MEDICINE,
//     EMERGENCY_ACUTE_CARE_CRITICAL_CARE,

//     PREVENTIVE_WELLNESS_OCCUPATIONAL_HEALTH,
//     PREVENTIVE_WELLNESS_PREVENTIVE_MEDICINE,
//     PREVENTIVE_WELLNESS_GERIATRICS,

//     REHABILITATION_PHYSICAL_THERAPY,
//     REHABILITATION_REHABILITATION,

//     SPECIALIZED_CARE_ENT,
//     SPECIALIZED_CARE_OPHTHALMOLOGY,
//     SPECIALIZED_CARE_DENTISTRY,
//     SPECIALIZED_CARE_ALLERGY_IMMUNOLOGY
// }

public type NewAppointment record {
    string doctorId;
    string patientId;
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

// public type NewUnsavedAppointment record {|
//     int appointmentNumber;
//     string doctorId;
//     string patientId;
//     int sessionId;
//     string category;
//     int medicalCenterId;
//     string medicalCenterName;
//     boolean isPaid;
//     decimal payment;
//     AppointmentStatus status;
//     time:Date appointmentTime;
//     time:Date createdTime;
//     time:Date lastModifiedTime;
// |};

public type AppointmentNumberCounter record {
    string _id;
    int sequence_value;
};


public type MedicalRecord record {
    time:Date startTime;
    time:Date endTime;
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
    string description;    
};

public type Diagnosis record {
    string[] category;
    string description;
};


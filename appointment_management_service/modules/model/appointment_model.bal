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
    string appointmentTime;  // accepted format -> 2024-10-03T10:15:30.00+05:30
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

public type Counter record {
    string _id;
    int sequenceValue;
};

//new appointment record for reviva
public type NewAppointmentRecord record {
    string sessionId;
    int timeSlot;
    string patientId;
    string patientName;
    int queueNumber;
    string[] aptCategories;
    string doctorId;
    string doctorName;
    string medicalCenterId;
    string medicalCenterName;
    decimal paymentAmount;
};

public type AppointmentRecord record {
    string _id?;
    int aptNumber;
    string sessionId;
    int timeSlot;
    string[] aptCategories;
    string doctorId;
    string doctorName;
    string medicalCenterId;
    string medicalCenterName;
    Payment payment;
    time:Date aptCreatedTimestamp;
    AppointmentStatus aptStatus;
    string patientId;
    string patientName;
    int queueNumber;
    MedicalRecord medicalRecord?;
};

public type Payment record {
    boolean isPaid;
    decimal amount;
    string handleBy;
    time:Date paymentTimestamp?;
};

public type MedicalRecord record {
    int aptNumber;
    time:Date startedTimestamp;
    time:Date endedTimestamp;
    string[] symptoms;
    Diagnosis diagnosis;
    Treatment treatments;
    string noteToPatient?;
    boolean isLabReportRequired;
    LabReport? labReport;
};

public type LabReport record {
    time:Date requestedTimestamp;
    boolean isHighPrioritize;
    string testType;
    string testName;
    string noteToLabStaff;
    int status;
    ReportDetails? reportDetails;
};

public type ReportDetails record {
    time:Date testStartedTimestamp;
    time:Date testEndedTimestamp;
    string? additionalNote;
    string[]? resultFiles;
};

public type Treatment record {
    string[] medications;
    string[] description;
};

public type Diagnosis record {
    string[] category;
    string[] description;
};

public type TempMedicalRecord record {|
    int aptNumber;
    string startedTimestamp;
    string endedTimestamp;
    string[] symptoms;
    Diagnosis diagnosis;
    Treatment treatments;
    string noteToPatient?;
    boolean isLabReportRequired;
    record {|
        string requestedTimestamp;
        boolean isHighPrioritize;
        string testType;
        string testName;
        string noteToLabStaff;
        int status;
        record {|
            string testStartedTimestamp;
            string testEndedTimestamp;
            string? additionalNote;
            string[]? resultFiles;
        |}? reportDetails;
    |}? labReport;
|};

    
    // Create a record type for the projected fields
    public type ProjectedAppointment record {
        string _id;
        string sessionId;
        int timeSlot;
        int queueNumber;
    };
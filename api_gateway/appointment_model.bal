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
    int aptNumber;
    string sessionId;
    int timeSlot;
    time:Date aptCreatedTimestamp;
    AppointmentStatus aptStatus;
    string patient;
    boolean isPayed;
    int queueNumber;
    MedicalRecord medicalRecord;
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
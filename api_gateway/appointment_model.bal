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
    string appointmentTime; // accepted format -> 2024-10-03T10:15:30.00Z
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

// session models
public type Session record {
    string _id?;
    time:Date endTimestamp?;
    time:Date startTimestamp?;
    string doctorId?;
    string medicalCenterId?;
    string[] aptCategories?;
    int payment?;
    string hallNumber?;
    string noteFromCenter?;
    string noteFromDoctor?;
    SessionStatus overallSessionStatus?;
    TimeSlot timeSlots;
};

public enum SessionStatus {
    UNACCEPTED,
    ACCEPTED,
    ACTIVE,
    ONGOING,
    CANCELLED,
    OVER
};

public type TimeSlot record {|
    int slotId;
    string startTime;
    string endTime?;
    int maxNoOfPatients;
    TimeSlotStatus status;
    Queue queue;
|};

public type Queue record {|
    int[] appointments;
    QueueOperations queueOperations;
|};

public type QueueOperations record {|
    int defaultIncrementQueueNumber;
    int ongoing;
    int nextPatient1;
    int nextPatient2;
    int[] finished;
    int[] absent;
|};

public enum TimeSlotStatus{
    NOT_STARTED,
    STARTED,
    FINISHED
};
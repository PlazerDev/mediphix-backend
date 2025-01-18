import ballerina/time;
import ballerina/http;

public type Doctor record {|
    string _id?;
    string name;
    string slmc;
    string nic;
    string[] education;
    string mobile;
    string[] specialization?;
    string email;
    string[] category?;
    string[] availability?;
    boolean verified;
    string[] patients?;
    string[] medical_centers?;
    string[] sessions?;
    string[] channellings?;
    string[] medical_records?;
    string[] lab_reports?;
    string profileImage?;
    string media_storage?;
|};


public type SessionSlot record {
    time:Date startTime;
    time:Date endTime;
    int patientCount;
};

public type Sessions record {
    string sessionId;
    string doctorName;
    string doctorMobile;
    string category;
    string medicalCenterId;
    string medicalCenterName;
    string medicalCenterMobile;
    string doctorNote;
    string medicalCenterNote;
    string sessionDate;
    SessionSlot timeSlots;
    SessionStatus sessionStatus;
    string location;
    decimal payment;
};

public enum SessionStatus {
    UNACCEPTED,
    ACCEPTED,
    ACTIVE,
    ONGOING,
    CANCELLED,
    OVER
};

public type DoctorMedicalCenterRequest record {|
    string doctorId;
    string medicalCenterId;
    // string doctorName;
    // string medicalCenterName;
    boolean verified;
|};


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

    public type AppointmentResponse record {
    int aptNumber;
    http:Created status;
};


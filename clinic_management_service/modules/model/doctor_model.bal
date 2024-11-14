import ballerina/time;

public type Doctor record {|
    string _id;
    string name;
    string slmc;
    string nic;
    string education;
    string mobile;
    string[] specialization;
    string email;
    string hospital;
    string category;
    string availability;
    decimal fee;
    boolean verified;
    string[] patients?;
    string[] medical_centers?;
    string[] sessions?;
    string[] channells?;
    string[] medical_records?;
    string[] lab_reports?;
|};

public type UnregisteredDoctor record {|
    string name;
    string slmc;
    string nic;
    string education;
    string mobile;
    string[] specialization;
    string email;
    string hospital;
    string category;
    string availability;
    decimal fee;
    boolean verified;
    string[] patients?;
    string[] medical_centers?;
    string[] sessions?;
    string[] channells?;
    string[] medical_records?;
    string[] lab_reports?;
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
    string medicalcenterId;
    string medicalcenterName;
    string medicalcenterMobile;
    string doctorNote;
    string medicalCenterNote;
    string sessionDate;
    SessionSlot timeSlots;
    SessionStatus sessionStatus;
    string location;
    decimal payment;
};

public enum SessionStatus {
    ACTIVE,
    ONGOING,
    CANCELLED,
    OVER
};
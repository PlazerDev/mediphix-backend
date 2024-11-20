import ballerina/time;

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
    string mediaStorage?;
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
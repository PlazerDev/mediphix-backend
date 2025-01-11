import ballerina/time;

public type Session record {
    string _id?;
    int sessionNumber?;
    string doctorId?;
    string doctorName?;
    string doctorMobile?;
    string category;
    string medicalCenterId;
    string medicalCenterName?;
    string medicalCenterMobile?;
    string doctorNote?;
    string medicalCenterNote?;
    string sessionDate;
    SessionStatus sessionStatus?;
    string location?;
    decimal payment?;
    boolean isAccepted?;
    int maxPatientCount?;
    int reservedPatientCount?;
    boolean isFull;
    string[] reservedPatientIds?;
    TimeSlot[] timeSlots;
    string[] timeSlotIds;
    string[] medicalStaffId?;
    time:Date createdTime?;
    time:Date lastModifiedTime?;
};

public type TimeSlot record {
    string _id?;
    int timeSlotNumber?;
    time:Date startTime;
    time:Date endTime;
    int maxPatientCount;
    int reservedPatientCount;
    boolean isFull;
    string[] appointmentIds;
    string[] patientId;
    string[] medicalStaffId;
    string[] patients;
};

public enum TimeslotStatus{
    NOTSTARTED,
    STARTED,
    FINISHED
};
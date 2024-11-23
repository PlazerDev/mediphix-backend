import ballerina/time;

public type Session record {
    string sessionId;
    string doctorId;
    string doctorName;
    string doctorMobile;
    string category;
    string medicalcenterId;
    string medicalcenterName;
    string medicalcenterMobile;
    string doctorNote;
    string medicalCenterNote;
    string sessionDate;
    SessionStatus sessionStatus;
    string location;
    decimal payment;
    string[] timeSlotId;
    string[] medicalStaffId;
};

public type TimeSlot record {
    time:Date startTime;
    time:Date endTime;
    int maxPatientCount;
    int patientCount;
    string[] appointmentId;
    string[] patientId;
    string[] medicalStaffId;
};

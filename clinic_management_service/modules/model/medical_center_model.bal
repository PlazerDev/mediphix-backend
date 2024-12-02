import ballerina/time;
public type Medical_Center record {|
    string name;
    string address;
    string mobile;
    string email;
    string district;
|};

public type MedicalCenter record {|
    string _id?;
    string name;
    string address;
    string mobile;
    string email;
    string district;
    boolean verified;
    string[] appointmentCategories?;
    string mediaStorage?;
    string specialNotes?;
    string[] doctors?;
    string[] appointments?;
    string[] patients?;
    string[] medicalCenterStaff?;
    decimal fee?;

|};

public type UnregisteredMedicalCEnter record {|
    string name;
    string address;
    string mobile;
    string email;
    byte idfront;
    byte idback;
    string district;
    boolean verified;
    decimal fee;
|};

public type DoctorRequests record {
    string session;
    string sessionVacancyId;
};


public type SessionVacancy record {
    string[] acceptedSessions;
    string[] doctorRequets;
    string category;
    UnacceptedSession[] unacceptedSessions;
    string note;
    string mobile;
    string medicalCenterId;
    time:Date createdTime?;
    time:Date modifiedTime?;
};

public type UnacceptedSession record{
    time:Date startTime;
    time:Date endTime;
    time:DayOfWeek days;
    boolean repeatStatus;
    boolean accepted;
};

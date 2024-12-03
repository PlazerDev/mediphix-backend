import ballerina/time;


public type MedicalCenter record {|
    string _id?;
    string name;
    string address;
    string mobile;
    string email;
    string district;
    boolean verified;
    string[] appointmentCategories?;
    string profileImage;
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
    string _id?;
    string[] acceptedSessions?;
    string[] doctorRequets;
    string[] categories;
    Session[] sessions;
    string note;
    string mobile;
    string medicalCenterId;
    time:Date createdTime?;
    time:Date modifiedTime?;
};

// public type UnAcceptedSession record{
//     time:Date startTime;
//     time:Date endTime;
//     time:DayOfWeek days;
//     boolean repeatStatus;
//     boolean accepted;
//     TimeSlot[] timeSlots;
// };


public type TimeslotNumberCounter record {
    string _id;
    int sequence_value;
};

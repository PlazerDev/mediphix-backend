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
    string description;
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
    string[] doctorRequests;
    string[] categories;
    Session[] sessions;
    string note;
    string mobile;
    string medicalCenterId;
    time:Date? createdTime;
    time:Date? modifiedTime;
};

public type Session record {
    int sessionId;
    string startTime;
    string endTime;
    time:Date rangeStartTimestamp;
    time:Date rangeEndTimestamp;
    Repetition repetition;
};

public type Repetition record {
    boolean isRepeat;
    string[] days;
    time:Date? noRepeatDateTimestamp;
};

public type Response record {
    int responseId;
    time:Date submittedTimestamp;
    string doctorId;
    string noteToPatient;
    string vacancyNoteToCenter;
    ResponseApplication[] responseApplications;
    boolean isCompletelyRejected;
};

public type ResponseApplication record {
    int appliedVacancySessionId;
    boolean isAccepted;
    decimal expectedPaymentAmount;
    TimeSlot[] noPatientsToTimeSlot;
};

public type TimeSlot record {
    int slotNumber;
    int maxNoPatients;
};

public type TimeslotNumberCounter record {
    string _id;
    int sequence_value;
};

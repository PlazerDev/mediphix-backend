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

public type NewSessionVacancy record {
    string[] aptCategories;
    string medicalCenterId;
    string mobileNumber;
    string vacancyNoteToDoctors;
    NewOpenSession[] openSessions;
};

public type SessionVacancy record {
    string _id?;
    DoctorResponse[] responses?;
    string[] aptCategories;
    string medicalCenterId;
    string mobileNumber;
    string vacancyNoteToDoctors;
    OpenSession[] openSessions;
    time:Date vacancyOpenedTimestamp;
    time:Date vacancyClosedTimestamp?;
};

//This model is used by doctor to respond to a session vacancy
public type DoctorResponse record {
    int responseId;
    time:Date submittedTimestamp;
    string doctorId;
    string noteToPatient;
    string vacancyNoteToCenter;
    DoctorResponseApplication[] responseApplications;
    boolean isCompletelyRejected;
};

public type NewOpenSession record {
    int sessionId?;
    string startTime;  // accepted string format -> 2024-10-03T10:15:30.00+05:30
    string endTime;    // accepted string format -> 2024-10-03T10:15:30.00+05:30
    string rangeStartTimestamp;
    string rangeEndTimestamp;
    Repetition repetition;
};

public type OpenSession record {
    int sessionId;
    time:Date startTime;
    time:Date endTime;
    time:Date rangeStartTimestamp;
    time:Date rangeEndTimestamp;
    Repetition repetition;
};

public type NewRepetition record {
    boolean isRepeat;
    string[] days;
    string noRepeatDateTimestamp?;
};

public type Repetition record {
    boolean isRepeat;
    string[] days;
    time:Date noRepeatDateTimestamp?;
};

public type DoctorResponseApplication record {
    int appliedVacancySessionId;
    boolean isAccepted;
    decimal expectedPaymentAmount;
    PatientCountPerTimeSlot[] numberOfPatientsPerTimeSlot;
};

public type PatientCountPerTimeSlot record {
    int slotNumber;
    int maxNumOfPatients;
};

public type Counter record {
    string _id;
    int sequenceValue;
};

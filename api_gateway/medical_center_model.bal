import ballerina/time;


public type NewSessionVacancy record {
    string[] aptCategories;
    string medicalCenterId;
    string mobile;
    string vacancyNoteToDoctors;
    NewOpenSession[] openSessions;
};

public type SessionVacancy record {
    string _id?;
    DoctorResponse[] responses?;
    string[] aptCategories;
    string medicalCenterId;
    string mobile;
    string vacancyNoteToDoctors;
    OpenSession[] openSessions;
    time:Date vacancyOpenedTimestamp;
    time:Date vacancyClosedTimestamp?;
};

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
    NewRepetition repetition;
};

public type OpenSession record {
    int sessionId?;
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
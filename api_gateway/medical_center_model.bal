import ballerina/time;

public type SessionVacancy record {
    string _id?;
    DoctorResponse[] responses?;
    string[] aptCategories;
    string medicalCenterId;
    string mobileNumber;
    string vacancyNoteToDoctors;
    string mobile;
    OpenSession[] openSessions;
    time:Date? vacancyOpenedTimestamp;
    time:Date? vacancyClosedTimestamp;
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

public type OpenSession record {
    int sessionId;
    time:Date startTime;
    time:Date endTime;
    time:Date rangeStartTimestamp;
    time:Date rangeEndTimestamp;
    Repetition repetition;
};

public type Repetition record {
    boolean isRepeat;
    string[] days;
    time:Date? noRepeatDateTimestamp;
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
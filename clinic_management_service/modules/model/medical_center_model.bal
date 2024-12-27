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
    Response[] responses?;
    string[] aptCategories;
    string medicalCenterId;
    string mobileNumber;
    string vacancyNoteToDoctors;
    string mobile;
    OpenSession[] openSessions;
    time:Date? vacancyOpenedTimestamp;
    time:Date? vacancyClosedTimestamp;
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

public type ResponseApplication record {
    int appliedVacancySessionId;
    boolean isAccepted;
    decimal expectedPaymentAmount;
    PatientCountPerTimeSlot[] numberOfPatientsPerTimeSlot;
};

public type PatientCountPerTimeSlot record {
    int slotNumber;
    int maxNumOfPatients;
};

public type TimeslotNumberCounter record {
    string _id;
    int sequenceValue;
};

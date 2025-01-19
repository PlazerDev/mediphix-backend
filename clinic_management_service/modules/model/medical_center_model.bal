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
    string[] MedicalCenterStaff?;
    string description?;
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


public type NewSessionVacancy record {
    string[] aptCategories;
    string medicalCenterId;
    string mobile;
    string vacancyNoteToDoctors;
    NewOpenSession[] openSessions;
};

//
public type SessionVacancy record {
    string _id?;
    int[] responses?;
    string[] aptCategories;
    string medicalCenterId;
    string mobile;
    string vacancyNoteToDoctors;
    OpenSession[] openSessions;
    time:Date vacancyOpenedTimestamp;
    time:Date vacancyClosedTimestamp?;
    string centerName?;
    string profileImage?;
};

public type McaSessionVacancy record {
    string _id?;
    McaDoctorResponse[] responses?;
    string[] aptCategories;
    string medicalCenterId;
    string mobile;
    string vacancyNoteToDoctors;
    OpenSession[] openSessions;
    time:Date vacancyOpenedTimestamp;
    time:Date vacancyClosedTimestamp?;
};

public type McaSessionVacancyDoctorDetails record{
    string name;
    string mobile;
    string email;
    string profileImage;
};

public type McaDoctorResponse record {
    int responseId?;
    time:Date submittedTimestamp;
    string doctorId;
    McaSessionVacancyDoctorDetails doctorDetails;
    string sessionVacancyId;
    string noteToPatient;
    string vacancyNoteToCenter;
    DoctorResponseApplication[] responseApplications;
    boolean isCompletelyRejected;
};
//


public type NewDoctorResponse record {
    int responseId?;
    string submittedTimestamp;
    string doctorId;
    string sessionVacancyId;
    string noteToPatient;
    string vacancyNoteToCenter;
    DoctorResponseApplication[] responseApplications;
    boolean isCompletelyRejected;
};

//This model is used by doctor to respond to a session vacancy
public type DoctorResponse record {
    int responseId?;
    time:Date submittedTimestamp;
    string doctorId;
    string sessionVacancyId;
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
    int sessionId;
    time:Date startTime;
    time:Date endTime;
    int numberOfTimeslots?;
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
    int appliedOpenSessionId;
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

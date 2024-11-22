import ballerina/time;

public type Doctor record {|
    string _id;
    string name;
    string slmc;
    string nic;
    string education;
    string mobile;
    string[] specialization;
    string email;
    string hospital;
    string category;
    string availability;
    decimal fee;
    boolean verified;
    string[] patients?;
    string[] medical_centers?;
    string[] sessions?;
    string[] channells?;
    string[] medical_records?;
    string[] lab_reports?;
|};

public type UnregisteredDoctor record {|
    string name;
    string slmc;
    string nic;
    string education;
    string mobile;
    string[] specialization;
    string email;
    string hospital;
    string category;
    string availability;
    decimal fee;
    boolean verified;
    string[] patients?;
    string[] medical_centers?;
    string[] sessions?;
    string[] channells?;
    string[] medical_records?;
    string[] lab_reports?;
|};

public type SessionSlot record {
    time:Date startTime;
    time:Date endTime;
    int patientCount;
};

public type Sessions record {
    string sessionId;
    string doctorName;
    string doctorMobile;
    string category;
    string medicalcenterId;
    string medicalcenterName;
    string medicalcenterMobile;
    string doctorNote;
    string medicalCenterNote;
    string sessionDate;
    SessionSlot timeSlots;
    SessionStatus sessionStatus;
    string location;
    decimal payment;
};

public enum SessionStatus {
    ACTIVE,
    ONGOING,
    CANCELLED,
    OVER
};

public type PatientRecord record {|
    FormData formData;
    PatientData patientData;
    AppointmentData appointmentData;
|};

public type FormData record {|
    string[] symptoms;
    string[] diagnosisCategories;
    string detailedDiagnosis;
    Medication[] medications;
    Procedure[] procedures;
    string special_note;
    LabReport[]? labReports; // Optional: Lab reports may not be defined
|};


public type Medication record {|
    string name;
    string frequency;
|};

public type Procedure record {|
    string procedure;
|};

public type LabReport record {|
    string test_type;
    string test_name;
    string priority_level;
    string note;
|};

public type PatientData record {|
    string name;
    int age;
    string sex;
    string nationality;
|};

public type AppointmentData record {|
    string refNumber;
    string date;
    string timeSlot;
    string medicalCenter;
    string doctor;
    string appointCatergory;
    int queueNo;
    string startTime;
|};

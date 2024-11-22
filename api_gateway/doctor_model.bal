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


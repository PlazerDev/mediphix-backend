

public type PatientWithCardNo record {
    *Patient;
    string cardNo;
};

public type Address record {|
    string house_number;
    string street;
    string city;
    string province;
    string postal_code;
|};

public type Patient record {|
    string mobile_number;
    string first_name;
    string last_name;
    string nic;
    string birthday;
    string email;
    string address;
    string nationality;
    string[] allergies?;
    string[] special_notes?;
|};

public type Appointment record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean paid;
    string appointmentDate;
|};

public type Doctor record {|
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
    
|};
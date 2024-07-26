
public type User record {|
    string email;
    string role;
    string password;
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
    boolean verified;

|};

public type MedicalCenter record {|
    string name;
    string address;
    string mobile;
    string email;
    string idfront;
    string idback;
    string district;
    boolean verified;
    decimal fee;

|};

public type PatientSignupData record {|
    string fname;
    string lname;
    string mobile;
    string dob;
    string email;
    string nationality;
    string nic;
    string address;
|};

public type DoctorSignupData record {|
    string name;
    string slmc;
    string nic;
    string education;
    string mobile;
    string[] specialization;
    string email;
    string password;
    string confirmpass;
    string idfront;
    string idback;
|};

//this is used for laboratory and medical centers
public type otherSignupData record {|
    string name;
    string address;
    string mobile;
    string email;
    string password;
    string confirmpass;
    string idfront;
    string idback;
    string district;
|};

public type ReturnMsg record {|
    string message;
    int statusCode;
|};


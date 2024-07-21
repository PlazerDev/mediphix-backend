public type User record {|
    string mobile_number;
    string role;
    string password;
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
    string specialization;
    string email;
    string password;
    string confirmpass;
    string idfront;
    string idback;
|};

public type ReturnMsg record {|
    string message;
|};

public type User record {|
    string email;
    string role;
    string password;
|};

public type MedicalCenter record {|
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

public type Laboratary record {|
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

public type PatientSignupData record {|
    string fname;
    string lname;
    string mobile;
    string dob;
    string email;
    string nationality;
    string nic;
    string address;
    string password;
    string confirmpass;
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
    byte idfront;
    byte idback;
    string district;
|};

public type ReturnMsg record {|
    string message;
    int statusCode;
|};

public type scimSearchResponse record {|
    json[] Resources;
    int totalResults;
    int startIndex;
    int itemsPerPage;
    string[] schemas;
|};



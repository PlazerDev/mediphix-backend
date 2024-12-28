
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
    string gender;
    string address;
    string password;
    string confirmPassword;
|};

public type DoctorSignupData record {|
    string name;
    string slmc;
    string nic;
    string[] education;
    string mobile;
    string[] specialization?;
    string email;
    string password;
    string confirmPassword;
    string profileImage?;
    byte[] profileImageFile?;
    byte[] idFront?;
    byte[] idBack?;
|};

//this is used for laboratory and medical centers
public type otherSignupData record {|
    string name;
    string address;
    string mobile;
    string email;
    string password;
    string confirmPassword;
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

public type registerMcaData record {
    string name;
    string nic;
    string email;
    string mobile;
    string password;
    string prifileImage?;

};

public type registereMcData record {
    string name;
    string address;
    string mobile;
    string email;
    string district;
    string specialNotes?;
    string profileImage?;

};

public type medicalCenterSignupData record {
    registerMcaData mcaData;
    registereMcData mcData;
};

public type medicalCenterStaffData record {
    string name;
    string nic;
    string email;
    string mobile;
    string centerId;
    string empId;
    string password;
};

public type medicalCenterReceptionistSignupData record {
    string name;
    string nic;
    string email;
    string mobile;
    string centerId;
    string empId;
    string password;
};

public type medicalCenterLabStaffSignupData record {
    string name;
    string nic;
    string email;
    string mobile;
    string centerId;
    string empId;
    string password;
};



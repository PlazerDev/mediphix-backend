
public type User record {|
    string _id?;
    string email;
    string role;
|};

public type MedicalCenterAdmin record {
    string _id?;
    string name;
    string nic;
    string mobile;
    string profileImage;
    string medicalCenterEmail;
    string userId;
};

public type MedicalCenterStaff record {
    string _id?;
    string name;
    string nic;
    string mobile;
    string empId;
    string centerId;
    string profileImage;
    string userId;
    string[] assignedSessions?;
};

public type MedicalCenterReceptionist record {
    string _id?;
    string name;
    string nic;
    string mobile;
    string empId;
    string centerId;
    string profileImage?;
    string userId;
};

public type MedicalCenterLabStaff record {
    string _id?;
    string name;
    string nic;
    string mobile;
    string empId;
    string centerId;
    string profileImage?;
    string userId;
};

public type FinalUserResult record {|
    string role;
    MedicalCenterAdmin|MedicalCenterStaff|MedicalCenterReceptionist|MedicalCenterReceptionist userData;
    MedicalCenterBrief medicalCenterData;
|};

public type MedicalCenterBrief record {|
    string _id;
    string name;
    string profileImage;
|};
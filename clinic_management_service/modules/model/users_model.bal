
public type User record {|
    string _id?;
    string email;
    string role;
|};

public type medicalCenterAdmin record {
    string _id?;
    string name;
    string nic;
    string mobile;
    string profileImage;
    string medicalCenterEmail;
    string userId;
};

public type medicalCenterStaff record {
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

public type medicalCenterReceptionist record {
    string _id?;
    string name;
    string nic;
    string mobile;
    string empId;
    string centerId;
    string profileImage?;
    string userId;
};

public type medicalCenterLabStaff record {
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
    medicalCenterAdmin|medicalCenterStaff|medicalCenterReceptionist|medicalCenterReceptionist userData;
    MedicalCenterBrief medicalCenterData;
|};

public type MedicalCenterBrief record {|
    string _id;
    string name;
    string profileImage;
|};
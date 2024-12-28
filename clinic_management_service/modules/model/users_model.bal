
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
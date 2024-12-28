
public type User record {|
    string _id?;
    string email;
    string role;
|};

public type medicalCenterAdmin record {
    string _id?;
    string name;
    string nic;
    string mobileNumber;
    string profileImage;
    string medicalCenterEmail;
    string userId;
};
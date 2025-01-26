
public type McaUserID record {
    string _id;
};

public type McaMedicalCenterEmail record {
    string _id;
    string medicalCenterEmail;
};

public type McaMedicalCenterId record {
    string _id;
};

public type McaJoinReq record {|
    string name;
    string profileImage;
    string reqId;
    int noOfCenters;
|};

public type JoinReq record {|
    string _id;
    string doctorId;
    string medicalCenterId?;
    boolean verified?;
|};

public type DoctorReq record {|
    string name;
    string profileImage;
    string[] medical_centers;
|};
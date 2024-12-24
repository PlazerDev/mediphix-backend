import ballerina/time;

public type McsUserID record {|
    string _id;
|};

public type McsAssignedSessionIdList record {|
    string[] assignedSessions;
|};

public type McsAssignedSession record {|
    time:Date endTimestamp;
    time:Date startTimestamp;
    string doctorId;
    string hallNumber;
    string noteFromCenter;
    string noteFromDoctor;
    string overallSessionStatus?;
|};

public type McsAssignedSessionWithDoctorDetails record {|
    time:Date endTimestamp;
    time:Date startTimestamp;
    McsDoctorDetails doctorDetails;
    string hallNumber;
    string noteFromCenter;
    string noteFromDoctor;
    string overallSessionStatus?;
|};

public type McsDoctorDetails record {|
    string name;
    string profilePhoto;
    string[] education;
    string[] specialization;
|};
import ballerina/time;

public type McsUserID record {|
    string _id;
|};

public type McsAssignedSessionIdList record {|
    string[] assignedSessions;
|};

public type McsAssignedSession record {|
    string _id?;
    time:Date endTimestamp;
    time:Date startTimestamp;
    string doctorId;
    string hallNumber;
    string noteFromCenter;
    string noteFromDoctor;
    string overallSessionStatus?;
|};

public type McsAssignedSessionWithDoctorDetails record {|
    string _id?;
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

public type McsTimeSlotList record {|
    McsTimeSlot[] timeSlot;
|};

public type McsTimeSlot record {|
    int slotId;
    string startTime;
    int maxNoOfPatients;
    string status;
    McsQueue queue;
|};

public type McsQueue record {|
    int[] appointments;
    McsQueueOperations queueOperations;
|};


public type McsQueueOperations record {|
    int defaultIncrementQueueNumber;
    int ongoing;
    int nextPatient1;
    int nextPatient2;
    int[] finished;
    int[] absent;
|};
import ballerina/time;

public type Session record {
    string _id?;
    time:Date endTimestamp?;
    time:Date startTimestamp?;
    string doctorId?;
    string medicalCenterId?;
    string[] aptCategories?;
    int payment?;
    string hallNumber?;
    string noteFromCenter?;
    string noteFromDoctor?;
    SessionStatus overallSessionStatus?;
    TimeSlot[] timeSlots;
};

public enum SessionStatus {
    UNACCEPTED,
    ACCEPTED,
    ACTIVE,
    ONGOING,
    CANCELLED,
    OVER
};

public type TimeSlot record {|
    int slotId;
    string startTime;
    string endTime?;
    int maxNoOfPatients;
    TimeSlotStatus status;
    Queue queue;
|};

public type Queue record {|
    int[] appointments;
    QueueOperations queueOperations;
|};

public type QueueOperations record {|
    int defaultIncrementQueueNumber;
    int ongoing;
    int nextPatient1;
    int nextPatient2;
    int[] finished;
    int[] absent;
|};

public enum TimeSlotStatus{
    NOT_STARTED,
    STARTED,
    FINISHED
};
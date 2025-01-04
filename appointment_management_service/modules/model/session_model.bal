import ballerina/time;

public type Session record {|
    time:Date endTimestamp?;
    time:Date startTimestamp?;
    string doctorId?;
    string medicalCenterId?;
    string[] aptCategories?;
    int payment?;
    string hallNumber?;
    string noteFromCenter?;
    string noteFromDoctor?;
    string overallSessionStatus?;
|};
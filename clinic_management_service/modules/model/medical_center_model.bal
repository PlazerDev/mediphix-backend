public type Medical_Center record {|
    string name;
    string address;
    string mobile;
    string email;
    string district;
|};

public type MedicalCenter record {|
    string _id?;
    string name;
    string address;
    string mobile;
    string email;
    string district;
    boolean verified;
    string[] appointmentCategories?;
    string mediaStorage?;
    string specialNotes?;
    string[] doctors?;
    string[] appointments?;
    string[] patients?;
    string[] medicalCenterStaff?;
    decimal fee?;

|};



public type UnregisteredMedicalCEnter record {|
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
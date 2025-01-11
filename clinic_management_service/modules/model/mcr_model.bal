import ballerina/time;
public type McrAppointment record {|
    int aptNumber?;
    string sessionId;
    int timeSlot;
    string aptCategories?;
    string doctorId;
    string doctorName?;
    string medicalCenterId?;
    string medicalCenterName?;
    McrPayment payment;
    time:Date aptCreatedTimestamp;
    string aptStatus;
    string patient?;
    string patientId;
    int queueNumber;
|};

public type McrPayment record {|
    time:Date ? paymentTimestamp;
    string handleBy;
    boolean isPaid;
    decimal amount;
|};

public type McrUpdatePayment record {|
    json paymentTimestamp;
    string handleBy;
    boolean isPaid;
    decimal amount;
|};

public type McrPatientData record {|
    string first_name;
    string last_name;
    string nic;
    string birthday;
    string profileImage;
    string gender;
|};

public type McrDoctorData record {|
    string name;
    string profileImage;
    string[] education;
    string[] specialization;
    string mobile;
|};

public type McrSessionData record {|
    time:Date startTimestamp;
    time:Date endTimestamp;
    string hallNumber;
    string noteFromCenter;
    string noteFromDoctor;
    string[] aptCategories;
|};

public type McrUser record {|
    string name?;
    string nic?;
    string mobile?;
    string empId?;
    string centerId?;
    string profileImage?;
    string userId?;
|};


// ############################# FINAL #########################
public type McrSearchPaymentFinalData record {|
    McrAptAndSessionFinalData aptAndSessionDetails;
    McrDoctorFinalData doctorDetails;
    McrPatientFinalData patientDetails;
    McrPaymentFinalData paymentDetails;
|};

public type McrAptAndSessionFinalData record {|
    int aptNumber;
    string[] aptCategories;
    string aptStatus;
    time:Date startTimestamp;
    time:Date endTimestamp;
    string hallNumber;
    int queueNumber;
    string noteFromCenter;
    string noteFromDoctor;
    time:Date aptCreatedTimestamp;
|};

public type McrPatientFinalData record {|
    string profileImage;
    string name;
    string age;
|};

public type McrDoctorFinalData record {|
    string profileImage;
    string name;
    string mobile;
    string[] education;
    string[] specialization;
|};

public type McrPaymentFinalData record {|
    boolean isPaid;
    time:Date ? paymentTimestamp;
    string handleBy;
    decimal amount;
|};



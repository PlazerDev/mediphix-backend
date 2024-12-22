public type MCS record {|
    string user_id;
    string first_name;
    string last_name;
    string nic;
    string medical_center_id;
|};

public type MCSwithMedicalCenter record {|
    string user_id;
    string first_name;
    string last_name;
    string nic;
    string medical_center_id;
    string medical_center_name;
    string medical_center_address;
    string medical_center_mobile;
    string medical_center_email;    
|};

public type McsUserID record {|
    string _id;
|};
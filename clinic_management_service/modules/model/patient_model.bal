// type Patient record {
//     string name;
//     string dob;
//     string address;
//     string phone;
//     string email;
// };



type PatientWithCardNo record {
    *Patient;
    string cardNo;
};

public type Address record {|
    string house_number;
    string street;
    string city;
    string province;
    string postal_code;
|};

type Patient record {|
    string mobile_number;
    string first_name;
    string last_name;
    string nic;
    string birthday;
    string email;
    Address address;
    string[] allergies;
    string[] special_notes;
|};

type Appointment record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean paid;
    string appointmentDate;
|};
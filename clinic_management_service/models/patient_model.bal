type Patient record {
    string name;
    string dob;
    string address;
    string phone;
    string email;
};

type PatientWithCardNo record {
    *Patient;
    string cardNo;
};
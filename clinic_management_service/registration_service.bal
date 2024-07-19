// import ballerina/http;

// import ballerina/io;

public function patientRegistrationService(PatientSignupData data) returns stream<User, error?>|error {
    if(data.fname.length() == 0) {
        return error("First name cannot be empty");
    }
    else{
        return error("ok");
    }
   
}


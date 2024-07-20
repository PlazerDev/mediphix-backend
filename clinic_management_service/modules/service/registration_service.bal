import clinic_management_service.model;

public function patientRegistrationService(model:PatientSignupData data) returns stream<model:User, error?>|error {
    if(data.fname.length() == 0) {
        return error("First name cannot be empty");
    }
    else{
        return error("ok");
    }
   
}


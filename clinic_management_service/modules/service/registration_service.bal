import clinic_management_service.model;
import clinic_management_service.dao;



public function patientRegistrationService(model:PatientSignupData data) returns error?{
    if(data.fname.length() == 0) {
        return error("First name cannot be empty");
    }
    else if(data.lname.length() == 0){
    
        return error("Last name cannot be empty");
    }
    else if(data.dob.length() == 0){
        return error("Date of Birth cannot be empty");
    }
    else{
        error? addPatientRecord = dao:patientRegistration(data);
        if addPatientRecord is error {
            return error("Error in adding patient record");
        }
        else {
            return ;
        }
        //add address details
    }
   
}

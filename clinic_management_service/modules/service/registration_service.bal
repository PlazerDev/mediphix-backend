import clinic_management_service.dao;
import clinic_management_service.model;

public function patientRegistrationService(model:PatientSignupData data) returns model:ReturnMsg {
    model:ReturnMsg addPatientReturnMsg = {message: "", statusCode: 0};
    if (data.fname.length() == 0) {
        addPatientReturnMsg.message = "First name cannot be empty";
        addPatientReturnMsg.statusCode = 400;
        return addPatientReturnMsg;
    }
    else if (data.lname.length() == 0) {
        addPatientReturnMsg.message = "Last name cannot be empty";
        addPatientReturnMsg.statusCode = 400;
        return addPatientReturnMsg;
    }
    else if (data.dob.length() == 0) {
        addPatientReturnMsg.message = "Date of Birth cannot be empty";
        addPatientReturnMsg.statusCode = 400;
        return addPatientReturnMsg;
    }
    else if (data.dob.length() == 0) {
        addPatientReturnMsg.message = "Date of Birth cannot be empty";
        addPatientReturnMsg.statusCode = 400;
        return addPatientReturnMsg;
    }

    else if(dao:isPatientExist(data.mobile) === true){
        addPatientReturnMsg.message="Mobile Number Already exist";
        addPatientReturnMsg.statusCode = 400;
        return addPatientReturnMsg;
    }
    else {
        error? addPatientRecord = dao:patientRegistration(data);
        if addPatientRecord is error {
            addPatientReturnMsg.message = addPatientRecord.message();
            addPatientReturnMsg.statusCode = 500;
            return addPatientReturnMsg;
        }
        else {
            addPatientReturnMsg.message = "Patient Registered Successfully";
            addPatientReturnMsg.statusCode = 200;
            return addPatientReturnMsg;
        }
        
        
    }

}

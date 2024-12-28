import clinic_management_service.dao;
import clinic_management_service.model;
import ballerina/io;
import ballerina/crypto;



public function registerPatient(model:PatientSignupData data) returns model:ReturnMsg {
    io:println("Inside register patient service"); //comment
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
    else if (data.mobile.length() !== 9) {
        addPatientReturnMsg.message = "Invalid Mobile Number";
        addPatientReturnMsg.statusCode = 400;
        return addPatientReturnMsg;
    }

    else if(dao:isPatientExist(data.mobile) === true){
        addPatientReturnMsg.message="Mobile Number Already exist";
        addPatientReturnMsg.statusCode = 500;
        return addPatientReturnMsg;
    }
    else {
        data.mobile ="0"+data.mobile;
        error?|json addPatientRecord = dao:patientRegistration(data);
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
public function registerDoctor(model:DoctorSignupData data) returns model:ReturnMsg {
    model:ReturnMsg addDoctorReturnMsg = {message: "", statusCode: 0};
    if (data.name.length() == 0) {
        addDoctorReturnMsg.message = "First name cannot be empty";
        addDoctorReturnMsg.statusCode = 400;
        return addDoctorReturnMsg;
    }
    else if (data.slmc.length() == 0) {
        addDoctorReturnMsg.message = "SLMC cannot be empty";
        addDoctorReturnMsg.statusCode = 400;
        return addDoctorReturnMsg;
    }
    else if (data.mobile.length() == 0) {
        addDoctorReturnMsg.message = "Mobile Number cannot be empty";
        addDoctorReturnMsg.statusCode = 400;
        return addDoctorReturnMsg;
    }
    else if (data.nic.length() == 0) {
        addDoctorReturnMsg.message = "NIC cannot be empty";
        addDoctorReturnMsg.statusCode = 400;
        return addDoctorReturnMsg;
    }
    else if (data.education.length() == 0) {
        addDoctorReturnMsg.message = "Education cannot be empty";
        addDoctorReturnMsg.statusCode = 400;
        return addDoctorReturnMsg;
    }
    else if (data.password !== data.confirmPassword) {
        addDoctorReturnMsg.message = "Password and Confirm Password should be same";
        addDoctorReturnMsg.statusCode = 400;
        return addDoctorReturnMsg;
    }

    else if(dao:isDoctorExist(data.email) === true){
        addDoctorReturnMsg.message="Email Already exist";
        addDoctorReturnMsg.statusCode = 500;
        return addDoctorReturnMsg;
    }
    else {
        data.password = genarateHash(data.password);
        error? addDoctorRecord = dao:doctorRegistration(data);
        if addDoctorRecord is error {
            addDoctorReturnMsg.message = addDoctorRecord.message();
            addDoctorReturnMsg.statusCode = 500;
            return addDoctorReturnMsg;
        }
        else {
            addDoctorReturnMsg.message = "Doctor Registered Successfully";
            addDoctorReturnMsg.statusCode = 200;
            io:println(addDoctorReturnMsg.message);
            return addDoctorReturnMsg;
        }
        
        
    }

}



public function registerMedicalCenter(model:medicalCenterSignupData data) returns model:ReturnMsg {
    model:ReturnMsg returnMsg = {message: "", statusCode: 0};
        error? addMedicalCenter = dao:registerMedicalCenter(data);
        if addMedicalCenter is error {
            returnMsg.message = addMedicalCenter.message();
            returnMsg.statusCode = 500;
            return returnMsg;
        }
        else {
            returnMsg.message = "Medical Center Registered Successfully";
            returnMsg.statusCode = 200;
            return returnMsg;
        }
        
}

public function registerMedicalCenterStaff(model:medicalCenterStaffData data) returns model:ReturnMsg {
    model:ReturnMsg returnMsg = {message: "", statusCode: 0};
        error? addMedicalCenter = dao:registerMedicalCenterStaff(data);
        if addMedicalCenter is error {
            returnMsg.message = addMedicalCenter.message();
            returnMsg.statusCode = 500;
            return returnMsg;
        }
        else {
            returnMsg.message = "Medical Center Registered Successfully";
            returnMsg.statusCode = 200;
            return returnMsg;
        }
        
}
public function registerLaboratary(model:otherSignupData data) returns model:ReturnMsg {
    model:ReturnMsg returnMsg = {message: "", statusCode: 0};
    if (data.name.length() == 0) {
        returnMsg.message = "Laboratary Name cannot be empty";
        returnMsg.statusCode = 400;
        return returnMsg;
    }
    else if (data.district.length() == 0) {
        returnMsg.message = "District cannot be empty";
        returnMsg.statusCode = 400;
        return returnMsg;
    }
    else if (data.address.length() == 0) {
        returnMsg.message = "Address cannot be empty";
        returnMsg.statusCode = 400;
        return returnMsg;
    }
    else if (data.mobile.length() == 0) {
        returnMsg.message = "mibile cannot be empty";
        returnMsg.statusCode = 400;
        return returnMsg;
    }
     else if (data.password !== data.confirmPassword) {
        returnMsg.message = "Password and Confirm Password should be same";
        returnMsg.statusCode = 400;
        return returnMsg;
    }

   
    else if(dao:isLaborataryExist(data.email) === true){
        returnMsg.message="Email Already exist";
        returnMsg.statusCode = 500;
        return returnMsg;
    }
    else {
        data.password = genarateHash(data.password);
        error? addLabRecord = dao:laborataryRegistration(data);
        if addLabRecord is error {
            returnMsg.message = addLabRecord.message();
            returnMsg.statusCode = 500;
            return returnMsg;
        }
        else {
            returnMsg.message = "Laboratary Registered Successfully";
            returnMsg.statusCode = 200;
            return returnMsg;
        }
        
        
    }

}


//this function can use for generate the hash value of the password and verify the password
//function return a string value.
//to verify the password, call function with enterd password and compare the return value with the stored password
public function genarateHash(string password)  returns string {
     string originalPasswordString = password;
    
    // Convert the original string to bytes
    byte[] originalPassword = originalPasswordString.toBytes();
    
    byte[] originalHash = crypto:hashMd5(originalPassword);
    
    // Convert the hash to a hex string for storing/comparing
    string originalHashHex = originalHash.toBase64();
   
    return originalHashHex;
}


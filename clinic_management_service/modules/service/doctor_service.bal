import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;




//get doctorId by email
public function doctorIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:doctorIdByEmail(email);
    return result;
}

//get doctorname by id
public function getDoctorDetails(string id) returns error|model:Doctor|model:InternalError {
    error|model:Doctor|model:InternalError result = check dao:getDoctorDetails(id);
    return result;
}
public function setDoctorJoinRequest(model:DoctorMedicalCenterRequest req) returns http:Created|error? {
     http:Created|error? result = check dao:setDoctorJoinRequest(req);
    return result;
}

public function getSessionDetails(string mobile) returns error|model:Sessions[]|model:InternalError {
    model:Sessions[]|model:InternalError result = check dao:getSessionDetails(mobile);
    return result;

}

public function getAllMedicalCenters() returns error|model:MedicalCenter[]|model:InternalError {
    model:MedicalCenter[]|model:InternalError result = check dao:getAllMedicalCenters();
    return result;
}

//get medical centers
public function getMyMedicalCenters(string id) returns error|model:MedicalCenter[]|model:InternalError
 {
    model:InternalError|model:MedicalCenter[] result = check dao:getMyMedicalCenters(id);
    return result;
}


public function submitPatientRecord(model:PatientRecord patientRecord) returns http:Created|model:InternalError|error {

    string refNumber = patientRecord.appointmentData.refNumber;
    string|model:InternalError|error patientIdResult = dao:getPatientIdByRefNumber(refNumber);


    string patientId;
    if patientIdResult is string {
        patientId = patientIdResult;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to retrieve patient ID. Please retry!",
            details: "record_book/patientId",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
    
    map<anydata> recordToStore = {
        patientId: patientId,
        patientRecord: patientRecord
    };

    http:Created|error? storeResult = dao:createPatientRecord(recordToStore);
    if storeResult is http:Created {
        return http:CREATED;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to store patient record. Please retry!",
            details: "record_book/patientRecord",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;



//get doctorname by mobile
public function getDoctorName(string mobile) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:getDoctorName(mobile);
    return result;
}

public function getSessionDetails(string mobile) returns error|model:Sessions[]|model:InternalError {
    model:Sessions[]|model:InternalError result = check dao:getSessionDetails(mobile);
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

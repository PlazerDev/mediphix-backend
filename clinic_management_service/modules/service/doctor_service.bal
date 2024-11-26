import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerinax/aws.s3;

configurable string AWS_ACCESS_KEY_ID = ?;
configurable string AWS_SECRET_ACCESS_KEY = ?;
configurable string AWS_REGION = ?;
configurable string S3_BUCKET_NAME = ?;

s3:ConnectionConfig amazonS3Config = {
    accessKeyId: AWS_ACCESS_KEY_ID,
    secretAccessKey: AWS_SECRET_ACCESS_KEY,
    region: AWS_REGION
};

s3:Client amazonS3Client = check new (amazonS3Config);

//get doctorId by email
public function doctorIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:doctorIdByEmail(email);
    return result;
}

//get doctorname by mobile
public function getDoctorName(string mobile) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:getDoctorName(mobile);
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

public function uploadMedia(string userType, string uploadType, string email, byte[] fileBytes, string fileName, string fileType, string extension) returns string|model:InternalError|error? {
    string fileNameNew = "other";
    if (userType === "doctor" && uploadType === "idFrontImage") {
        fileNameNew = "doctor-resources/" + email + "/" + "idFrontImage";
    } else if (userType === "doctor" && uploadType === "idBackImage") {
        fileNameNew = "doctor-resources/" + email + "/" + "idBackImage";
    } else if (userType === "doctor" && uploadType === "medicalCertificates") {
        fileNameNew = "doctor-resources/" + email + "/" + "medicalCertificates" + "/" + fileName;
    } else if (userType === "doctor" && uploadType === "profileImage") {
        fileNameNew = "doctor-resources/" + email + "/" + "profileImage";
    } else if (userType === "medicalCenter" && uploadType === "logo") {
        fileNameNew = "medical-center-resources/" + email + "/" + "logo";
    } else if (userType === "medicalCenter" && uploadType === "license") {
        fileNameNew = "medical-center-resources/" + email + "/" + "license";
    } else if (userType === "patient" && uploadType === "prescription") {
        fileNameNew = "patient-resources/" + email + "/" + "prescription" + "/" + fileName;
    } else if (userType === "patient" && uploadType === "reports") {
        fileNameNew = "patient-resources/" + email + "/" + "reports" + "/" + fileName;
    } else if (userType === "patient" && uploadType === "profileImage") {
        fileNameNew = "patient-resources/" + email + "/" + "profileImage";
    } else {
        model:ErrorDetails errorDetails = {
            message: "Invalid upload type",
            details: "doctor/uploadmedia",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
    string contentType = fileType + "/" + extension;
    map<string> metadata = {
        "Content-Type": contentType
    };
    s3:ObjectCreationHeaders headers = {
        contentType: contentType
    };

    error? result = amazonS3Client->createObject(S3_BUCKET_NAME, fileNameNew, fileBytes, (), headers, metadata);
    if (result is error) {
        io:println("Error uploading media: ", result);
        model:ErrorDetails errorDetails = {
            message: "Failed to upload media. Please retry!",
            details: "doctor/uploadmedia",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
    return "Success";

}

// public function uploadToS3(string email, string filePath, string mimeType) returns string {
//     string contentType = "application/pdf";
//     string key = fileName;
//     string content = fileContent;
//     error?|s3:PutObjectResult result = s3:putObject(amazonS3Client, S3_BUCKET_NAME, key, content, contentType);
//     if (result is error) {
//         return "Error";
//     } else {
//         return "Success";
//     }
// }

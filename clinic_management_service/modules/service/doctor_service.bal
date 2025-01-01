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

//get doctorname by id
public function getDoctorDetails(string id) returns error|model:Doctor|model:InternalError {
    error|model:Doctor|model:InternalError result = check dao:getDoctorDetails(id);
    return result;
}

public function setDoctorJoinRequest(model:DoctorMedicalCenterRequest req) returns http:Created|error? {
    http:Created|error? result = check dao:setDoctorJoinRequest(req);
    return result;
}

public function getSessionDetailsByDoctorId(string doctorId) returns error|model:Session[]|model:InternalError {
    model:Session[]|model:InternalError result = check dao:getSessionDetailsByDoctorId(doctorId);
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

public function getDoctorSessionVacancies(string doctorId) returns error|model:SessionVacancy[]|model:InternalError {
    model:SessionVacancy[]|model:InternalError result = check dao:getDoctorSessionVacancies(doctorId);
    return result;
}

public function respondDoctorToSessionVacancy(model:DoctorResponse response) returns http:Created|model:InternalError|error? {
    http:Created|model:InternalError|error? result = check dao:respondDoctorToSessionVacancy(response);
    if (result is error?) {
        model:ErrorDetails errorDetails = {
            message: "Failed to respond to session vacancy. Please retry!",
            details: "doctor/respondDoctorToSessionVacancy",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
    return result;
}

public function uploadMedia(string userType, string uploadType, string email, byte[] fileBytes, string fileName, string fileType, string extension) returns string|model:InternalError|error? {
    string emailHead = getEmailHead(email);
    string fileNameNew = "other";
    if (userType === "doctor" && uploadType === "idFrontImage") {
        fileNameNew = "doctor-resources/" + emailHead + "/" + "idFrontImage";
    } else if (userType === "doctor" && uploadType === "idBackImage") {
        fileNameNew = "doctor-resources/" + emailHead + "/" + "idBackImage";
    } else if (userType === "doctor" && uploadType === "medicalCertificates") {
        fileNameNew = "doctor-resources/" + emailHead + "/" + "medicalCertificates" + "/" + fileName;
    } else if (userType === "doctor" && uploadType === "profileImage") {
        fileNameNew = "doctor-resources/" + emailHead + "/" + "profileImage";
    } else if (userType === "medicalCenter" && uploadType === "logo") {
        fileNameNew = "medical-center-resources/" + emailHead + "/" + "logo";
    } else if (userType === "medicalCenter" && uploadType === "license") {
        fileNameNew = "medical-center-resources/" + emailHead + "/" + "license";
    } else if (userType === "patient" && uploadType === "prescription") {
        fileNameNew = "patient-resources/" + emailHead + "/" + "prescription" + "/" + fileName;
    } else if (userType === "patient" && uploadType === "reports") {
        fileNameNew = "patient-resources/" + emailHead + "/" + "reports" + "/" + fileName;
    } else if (userType === "patient" && uploadType === "profileImage") {
        fileNameNew = "patient-resources/" + emailHead + "/" + "profileImage";
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
    } else {
        io:println("Success uploading media: ", result);
    }
    return "Success";

}

public function getEmailHead(string email) returns string {
    string:RegExp emailHeadRegExp = re `@`;
    string[] emailChunks = emailHeadRegExp.split(email);
    string emailHead = string:'join("", ...emailChunks);
    return emailHead;
}

public function getMedia(string userType, string uploadType, string email) returns stream<byte[], io:Error?>|error? {
    string emailHead = getEmailHead(email);
    byte[] fileBytes = [];
    string fileName = "other";
    if (userType === "doctor" && uploadType === "idFrontImage") {
        fileName = "doctor-resources/" + emailHead + "/" + "idFrontImage";
    } else if (userType === "doctor" && uploadType === "idBackImage") {
        fileName = "doctor-resources/" + emailHead + "/" + "idBackImage";
    } else if (userType === "doctor" && uploadType === "medicalCertificates") {
        fileName = "doctor-resources/" + emailHead + "/" + "medicalCertificates";
    } else if (userType === "doctor" && uploadType === "profileImage") {
        fileName = "doctor-resources/" + emailHead + "/" + "profileImage";
    } else if (userType === "medicalCenter" && uploadType === "logo") {
        fileName = "medical-center-resources/" + emailHead + "/" + "logo";
    } else if (userType === "medicalCenter" && uploadType === "license") {
        fileName = "medical-center-resources/" + emailHead + "/" + "license";
    } else if (userType === "patient" && uploadType === "prescription") {
        fileName = "patient-resources/" + emailHead + "/" + "prescription";
    } else if (userType === "patient" && uploadType === "reports") {
        fileName = "patient-resources/" + emailHead + "/" + "reports";
    } else if (userType === "patient" && uploadType === "profileImage") {
        fileName = "patient-resources/" + emailHead + "/" + "profileImage";
    } else {
        return error("Invalid upload type");
    }

    stream<byte[], io:Error?>|error objectStreamResult = amazonS3Client->getObject(S3_BUCKET_NAME, fileName);

    if objectStreamResult is error {
        io:println("Error retrieving object: ", objectStreamResult.message());
        return error("Failed to retrieve object from S3");
    }

    // stream<byte[], io:Error?> objectStream = <stream<byte[], io:Error?>>objectStreamResult;

    return objectStreamResult;
}

public function getMediaLink(string userType, string uploadType, string email) returns string|error? {
    string emailHead = getEmailHead(email);
    string fileName = "other";
    string link = "";
    if (userType === "doctor" && uploadType === "idFrontImage") {
        fileName = "doctor-resources/" + emailHead + "/" + "idFrontImage";
    } else if (userType === "doctor" && uploadType === "idBackImage") {
        fileName = "doctor-resources/" + emailHead + "/" + "idBackImage";
    } else if (userType === "doctor" && uploadType === "medicalCertificates") {
        fileName = "doctor-resources/" + emailHead + "/" + "medicalCertificates";
    } else if (userType === "doctor" && uploadType === "profileImage") {
        fileName = "doctor-resources/" + emailHead + "/" + "profileImage";
    } else if (userType === "medicalCenter" && uploadType === "logo") {
        fileName = "medical-center-resources/" + emailHead + "/" + "logo";
    } else if (userType === "medicalCenter" && uploadType === "license") {
        fileName = "medical-center-resources/" + emailHead + "/" + "license";
    } else if (userType === "patient" && uploadType === "prescription") {
        fileName = "patient-resources/" + emailHead + "/" + "prescription";
    } else if (userType === "patient" && uploadType === "reports") {
        fileName = "patient-resources/" + emailHead + "/" + "reports";
    } else if (userType === "patient" && uploadType === "profileImage") {
        fileName = "patient-resources/" + emailHead + "/" + "profileImage";
    } else {
        return error("Invalid upload type");
    }

    return fileName;
}

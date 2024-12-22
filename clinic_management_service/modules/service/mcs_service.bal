import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/http;
import ballerina/time;

public function getMCSMemberInformationService(string userId) returns model:MCSwithMedicalCenter|model:NotFoundError|model:InternalError {
    model:MCS|model:NotFoundError|error? mcsData = dao:getMCSInfoByUserID(userId);
    if mcsData is model:MCS {
        model:MedicalCenter|model:NotFoundError|error? medicalCenterData = dao:getMedicalCenterInfoByID(mcsData.medical_center_id, userId);
        if medicalCenterData is model:MedicalCenter {
            model:MCSwithMedicalCenter mcsWithMedicalCenter = {
                user_id: mcsData.user_id,
                first_name: mcsData.first_name,
                last_name: mcsData.last_name,
                nic: mcsData.nic,
                medical_center_id: mcsData.medical_center_id,
                medical_center_name: medicalCenterData.name,
                medical_center_address: medicalCenterData.address,
                medical_center_mobile: medicalCenterData.mobile,
                medical_center_email: medicalCenterData.email
            };
            return mcsWithMedicalCenter;
        }
        else if medicalCenterData is model:NotFoundError {
            return medicalCenterData;
        } else {
            model:ErrorDetails errorDetails = {
                message: "Unexpected internal error occurred, please retry!",
                details: string `mcs/${userId}`,
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
    } else if mcsData is model:NotFoundError {
        return mcsData;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `mcs/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function createSessionVacancy(model:SessionVacancy sessionVacancy) returns http:Created|model:InternalError|error? {
    http:Created|error? vacancyResult = dao:createSessionVacancy(sessionVacancy);
    http:Created|error? sessionsResult = dao:createSessions(sessionVacancy);
    if (vacancyResult is http:Created) {
        return vacancyResult;
    }

    model:ErrorDetails errorDetails = {
        message: "Unexpected internal error occurred, please retry!",
        details: "sessionVacancy",
        timeStamp: time:utcNow()
    };

    model:InternalError internalError = {body: errorDetails};
    return internalError;
}

public function createSessions(model:SessionVacancy vacancy) returns http:Created|model:InternalError|error? {
    http:Created|error? result = dao:createSessions(vacancy);
    if (result is http:Created) {
        return result;
    }

    model:ErrorDetails errorDetails = {
        message: "Unexpected internal error occurred, please retry!",
        details: "sessions",
        timeStamp: time:utcNow()
    };

    model:InternalError internalError = {body: errorDetails};
    return internalError;
}


public function getMcsIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:getMcsIdByEmail(email);
    return result;
}
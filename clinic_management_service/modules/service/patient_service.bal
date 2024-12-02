import clinic_management_service.dao;
import clinic_management_service.model;

import ballerina/time;

public function getPatientById(string userId) returns model:Patient|model:ValueError|model:NotFoundError|model:InternalError {

    if (userId.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Invalid user id",
            details: string `patient/${userId}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }
    // } else if (mobile.matches(re `^\d{9}$`)) {
    //     //regex should be `^(0|(\+94))\d{9}$` if we consider +94 or 0 at start of the mobile number
    //     model:ErrorDetails errorDetails = {
    //         message: string `This mobile number: ${mobile} is not valid. Please provide a valid Sri Lankan mobile number.`,
    //         details: string `patient/${mobile}`,
    //         timeStamp: time:utcNow()
    //     };
    //     model:ValueError valueError = {
    //         body: errorDetails
    //     };
    //     return valueError;
    // }
    model:Patient|model:NotFoundError|error? patient = dao:getPatientById(userId);
    if patient is model:Patient|model:NotFoundError {
        return patient;
    } else if patient is error {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `patient/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `patient/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getPatientByEmail(string email) returns model:Patient|model:ValueError|model:NotFoundError|model:InternalError {

    if (email.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a mobile number",
            details: string `patient/${email}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    model:Patient|model:NotFoundError|error? patient = dao:getPatientByEmail(email);
    if patient is model:Patient|model:NotFoundError {
        return patient;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `patient/${email}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getAppointments(string mobile) returns model:ReturnResponse|model:Appointment[]|error {

    if (mobile.length() === 0) {
        model:ReturnResponse returnResponse = {
            message: "Please provide a mobile number",
            statusCode: 400
        };
        return returnResponse;
    }

    model:Appointment[]|model:ReturnResponse appointments = check dao:getAppointments(mobile);
    if appointments is model:Appointment[] {
        return appointments;
    } else if appointments is model:ReturnResponse {
        return appointments;
    }

}

public function getAllDoctors() returns error|model:Doctor[]|model:InternalError {
    model:Doctor[]|model:InternalError result = check dao:getAllDoctors();
    return result;
}

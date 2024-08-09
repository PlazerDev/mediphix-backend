import clinic_management_service.dao;
import clinic_management_service.model;
import ballerina/time;


function savepatientService(model:Patient patient) {

    error? savepatientResult = dao:savePatient(patient);
    if savepatientResult is error {

    }

    // do {
    //     mongodb:Client mongoDb = check new (connection = "mongodb+srv://username:password");
    // } on fail var e {

    // }
}

public function getPatient(string mobile) returns model:Patient|model:ValueError|model:NotFoundError|model:InternalError {

    if (mobile.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a mobile number",
            details: string `patient/${mobile}`,
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
    model:Patient|model:NotFoundError|error? patient = dao:getPatient(mobile);
    if patient is model:Patient|model:NotFoundError {
        return patient;
    } else if patient is error {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry1!",
            details: string `patient/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry2!",
            details: string `patient/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

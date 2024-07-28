import clinic_management_service.dao;
import clinic_management_service.model;
import ballerina/time;

public function getMCSMemberInformationService(string userId) returns model:MCS|model:NotFoundError|model:InternalError{
    model:MCS|model:NotFoundError|error? mcsData = dao:getMCSInfoByUserID(userId);
    if mcsData is model:MCS|model:NotFoundError {
        return mcsData;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `mcs/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

import clinic_management_service.model;
import clinic_management_service.dao;


// get the [userId] by [email]
public function mcrGetUserIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:mcrGetUserIdByEmail(email);
    return result;
}
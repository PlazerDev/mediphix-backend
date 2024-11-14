import clinic_management_service.model;
import clinic_management_service.dao;
public function getSessionDetails(string mobile) returns error|model:Sessions[]|model:InternalError {
    model:Sessions[]|model:InternalError result = check dao:getSessionDetails(mobile);
    return result;
    
}
import clinic_management_service.model;
import clinic_management_service.dao;



//get doctorname by mobile
public function getDoctorName(string mobile) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:getDoctorName(mobile);
    return result;
}
public function getSessionDetails(string mobile) returns error|model:Sessions[]|model:InternalError {
    model:Sessions[]|model:InternalError result = check dao:getSessionDetails(mobile);
    return result;
    
}


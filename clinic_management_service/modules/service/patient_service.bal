import clinic_management_service.dao;
import clinic_management_service.model;

function savepatientService(model:Patient patient) {
    

    error? savepatientResult = dao:savePatient(patient);
    if savepatientResult is error {
        
    }

    // do {
	//     mongodb:Client mongoDb = check new (connection = "mongodb+srv://username:password");
    // } on fail var e {
    	
    // }
}
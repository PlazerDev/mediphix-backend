

function savepatientService(Patient patient) {
    

    error? savepatientResult = savepatient(patient);
    if savepatientResult is error {

    }

    // do {
	//     mongodb:Client mongoDb = check new (connection = "mongodb+srv://username:password");
    // } on fail var e {
    	
    // }
}
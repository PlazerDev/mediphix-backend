import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;
import ballerina/http;






//get doctorId by email
public function doctorIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

     map<json> filter = {"email":email};
     map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name":1,
        "slmc":1,
        "nic":1,
        "education":1,
        "mobile":1,
        "specialization":1,
        "email":1,
        "category":1,
        "availability":1,
        "verified":1,
        "patients":  [{"$toString": "$_id"}],
        "medical_centers":  [{"$toString": "$_id"}],
        "sessions":  [{"$toString": "$_id"}],
        "channellings":  [{"$toString": "$_id"}],
        "medical_records":  [{"$toString": "$_id"}],
        "lab_reports":[{"$toString": "$_id"}],
        "media_storage":1
    }; 
    model:Doctor|mongodb:Error? findResults =  check doctorCollection->findOne(filter, {},projection);
    io:println("Find result",findResults);
    if findResults is model:Doctor {
        return findResults._id ?: "";
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving doctor ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function getSessionDetailsByDoctorId(string doctorId) returns error|model:InternalError|model:Session[]{    
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    map<json> sessionProjection = {
    "_id": {"$toString": "$_id"}, // Convert sessionId to string
    "doctorId": {"$toString": "$doctorId"}, // Convert doctorId to string
    "doctorName": 1, // Include doctorName as is
    "doctorMobile": 1, // Include doctorMobile as is
    "category": 1, // Include category as is
    "medicalcenterId": {"$toString": "$medicalcenterId"}, // Convert medicalcenterId to string
    "medicalcenterName": 1, // Include medicalcenterName as is
    "medicalcenterMobile": 1, // Include medicalcenterMobile as is
    "doctorNote": 1, // Include doctorNote as is
    "medicalCenterNote": 1, // Include medicalCenterNote as is
    "sessionDate": 1, // Include sessionDate as is
    "sessionStatus": 1, // Include sessionStatus as is
    "location": 1, // Include location as is
    "payment": 1, // Include payment as is
    "maxPatientCount": 1, // Include maxPatientCount as is
    "reservedPatientCount": 1, // Include reservedPatientCount as is
    "timeSlotId":[{"$toString": "$timeSlotId"}] ,
    "medicalStaffId": [{"$toString": "$medicalStaffId"}]
};

    
    map<json> filter = {"_id": {"$oid": doctorId}};
    stream<model:Session, error?>|mongodb:Error? findResults =  check sessionCollection->find(filter, {}, sessionProjection,model:Session);
    
    if findResults is stream<model:Session, error?> {
        model:Session[]|error Session = from model:Session ses in findResults
            select ses;
            io:println("Session",Session);
        return Session;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving session details",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
   
 
    
}

//get my medical centers.in this method we find medical centers doctor array and find the medical centers which has the doctor
public function getMyMedicalCenters(string id) returns error|model:InternalError|model:MedicalCenter[] {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");
 
     map<json> filter = {"doctors": {"$oid": id}};

    // Optional: You can specify which fields to retrieve in the projection
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "address": 1,
        "mobile": 1,
        "email": 1,
        "district": 1,
        "verified": 1,
        "appointmentCategories": 1,
        "mediaStorage": 1,
        "specialNotes": 1,
        "doctors":  [{"$toString": "$_id"}],
        "appointments":  [{"$toString": "$_id"}],
        "patients":  [{"$toString": "$_id"}],
        "medicalCenterStaff":  [{"$toString": "$_id"}],
        "fee": 1
    };  

    io:println("debug",id);

    stream<model:MedicalCenter, error?>|mongodb:Error? findResults = check medicalCenterCollection->find(filter, {},projection, model:MedicalCenter);

    if findResults is stream<model:MedicalCenter, error?> {
        model:MedicalCenter[]|error medicalCenters = from model:MedicalCenter mc in findResults
            select mc; 
        return medicalCenters;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving medical centers",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}






public function getDoctorDetails(string id) returns error|model:Doctor|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

    map<json> filter = {"_id": {"$oid": id}};

    // Optional: You can specify which fields to retrieve in the projection
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name":1,
        "slmc":1,
        "nic":1,
        "education":1,
        "mobile":1,
        "specialization":1,
        "email":1,
        "category":1,
        "availability":1,
        "verified":1,
        "patients":  [{"$toString": "$_id"}],
        "medical_centers":  [{"$toString": "$_id"}],
        "sessions":  [{"$toString": "$_id"}],
        "channellings":  [{"$toString": "$_id"}],
        "medical_records":  [{"$toString": "$_id"}],
        "lab_reports":[{"$toString": "$_id"}],
        "media_storage":1
    };
    model:Doctor|mongodb:Error? findResults =  check   doctorCollection->findOne(filter , {}, projection,model:Doctor);
 
    if findResults is model:Doctor {
        return findResults;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving doctor name",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function getAllMedicalCenters() returns error|model:MedicalCenter[]|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection medicalCenterCollection = check mediphixDb->getCollection("medical_center");
    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "address": 1,
        "mobile": 1,
        "email": 1,
        "district": 1,
        "verified": 1,
        "appointmentCategories": 1,
        "mediaStorage": 1,
        "specialNotes": 1,
        "doctors": [{"$toString": "$_id"}],
        "appointments":  [{"$toString": "$_id"}],
        "patients":  [{"$toString": "$_id"}],
        "medicalCenterStaff":  [{"$toString": "$_id"}],
        "fee": 1
    };

    stream<model:MedicalCenter, error?>|mongodb:Error? findResults =  check medicalCenterCollection->find({},{},projection,model:MedicalCenter);
    if findResults is stream<model:MedicalCenter, error?> {
        model:MedicalCenter[]|error medicalCenters = from model:MedicalCenter mc in findResults
            select mc; 
        return medicalCenters;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving medical centers",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};
        return userNotFound;
    }
}

public function getPatientIdByRefNumber(string refNumber) 
    returns string|model:InternalError|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");

    map<anydata>? appointment = check appointmentCollection->findOne({appointmentNumber: refNumber});
    
    if appointment is map<anydata> {
        anydata patientId = appointment["patientId"];
        if patientId is string {
            return patientId;
        } else {
            model:ErrorDetails errorDetails = {
                message: "Patient ID is not a string in the database.",
                details: "refNumber/" + refNumber,
                timeStamp: time:utcNow()
            };
            model:InternalError internalError = {body: errorDetails};
            return internalError;
        }
    } else {
        model:ErrorDetails errorDetails = {
            message: "Failed to find the appointment for the given reference number.",
            details: "refNumber/" + refNumber,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function createPatientRecord(map<anydata> recordToStore) returns http:Created|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection recordBookCollection = check mediphixDb->getCollection("record_book");

    check recordBookCollection->insertOne(recordToStore);
    return http:CREATED;
}

public function setDoctorJoinRequest(model:DoctorMedicalCenterRequest  req) returns http:Created|error?{
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorRequestCollection = check mediphixDb->getCollection("doctor_join_request_to_mc");

    check doctorRequestCollection->insertOne(req);
    return http:CREATED;
}

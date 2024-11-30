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

public function getSessionDetails(string mobile) returns error|model:InternalError|model:Sessions[]{    
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    
    // model:Sessions session = {
    //     sessionId: "1",
    //     doctorName: "Dr. John Doe",
    //     doctorMobile: "94712345678",
    //     category: "General",
    //     medicalcenterId: "1",
    //     medicalcenterName: "Asiri Medical Center",
    //     medicalcenterMobile: "94712345678",
    //     doctorNote: "Please be on time",
    //     medicalCenterNote: "Please be on time",
    //     sessionDate: "2021-09-01",
    //     timeSlots: {
    //         startTime: check time:utcToCivil(check time:utcFromString("2007-12-03T10:15:30.00Z")),
    //         endTime:  check time:utcToCivil(check time:utcFromString("2007-12-04T10:15:30.00Z")),
    //         patientCount: 10
    //     },
    //     sessionStatus: "ACTIVE",
    //     location: "Colombo",
    //     payment: 1000.00
    // };

    // mongodb:Error? postResult = check  sessionCollection->insertOne(session);

    // time:Date date=check time:utcNow();
    
    map<json> filter = { "doctorMobile": mobile };
    stream<model:Sessions, error?>|mongodb:Error? findResults =  check sessionCollection->find(filter, {}, (),model:Sessions);
    
    if findResults is stream<model:Sessions, error?> {
        model:Sessions[]|error Sessions = from model:Sessions ses in findResults
            select ses;
        return Sessions;
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






public function getDoctorName(string mobile) returns error|string|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection doctorCollection = check mediphixDb->getCollection("doctor");

    map<json> filter = { "mobile": mobile };
    model:Doctor|mongodb:Error? findResults =  check   doctorCollection->findOne(filter);
    io:println("Find result",findResults);
    
    if findResults is model:Doctor {
        return findResults.name;
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

import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;


public function mcrGetUserIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Collection userCollection = check initDatabaseConnection("user");

    map<json> filter = {"email":email};
    map<json> projection = {
        "_id": {"$toString": "$_id"}
    
    };

    model:McsUserID|mongodb:Error? findResults = userCollection->findOne(filter, {}, projection);

    if findResults is model:McsUserID {
        return findResults._id;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving MCR ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}


  # Fetch the appointment details using the aptNumber 
    # 
    # 
    # + aptNumber - appointment number
    # + return - sessionId, patientId, doctorId, aptStatus, aptCreatedTimestamp, queueNumber, payment, timeslot id
public function mcrGetAptDetails(int aptNumber) returns model:McrAppointment|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("appointment");

    map<json> filter = {
        "aptNumber": aptNumber
    };

   map<json> projection = {
        "_id": 0,
        "sessionId": 1,
        "patientId": 1,
        "doctorId": 1,
        "aptStatus": 1,
        "aptCreatedTimestamp": 1,
        "queueNumber": 1,
        "payment": 1,
        "timeSlot": 1
    };

    model:McrAppointment ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch the patient details using the patientId 
    # 
    # 
    # + patientId - Patient id (_id)
    # + return - on sucess [ first_name, last_name, nic, gender, birthday, profileImage ]
public function mcrGetPatientDetails(string patientId) returns model:McrPatientData|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("patient");
   
    map<json> filter = {
        "_id": {"$oid": patientId}
    };

   map<json> projection = {
        "_id": 0,
        "first_name": 1,
        "last_name": 1,
        "nic": 1,
        "gender": 1,
        "birthday": 1,
        "profileImage": 1
    };

    model:McrPatientData ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch the doctor details using the doctorId 
    # 
    # 
    # + doctorID - Doctor id (_id)
    # + return - on sucess [ name, profileImage, education, specialization ]
public function mcrGetDoctorDetails(string doctorID) returns model:McrDoctorData|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("doctor");
   
    map<json> filter = {
        "_id": {"$oid": doctorID}
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "profileImage": 1,
        "education": 1,
        "specialization": 1,
        "mobile": 1
    };

    model:McrDoctorData ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch the session details using the sessionId 
    # 
    # 
    # + sessionId - Session id (_id)
    # + return - on sucess [ startTimestamp, endTimestamp, hallNumber, noteFromCenter, noteFromDoctor ]
public function mcrGetSessionDetails(string sessionId) returns model:McrSessionData|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("session");
   
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

   map<json> projection = {
        "_id": 0,
        "startTimestamp": 1,
        "endTimestamp": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1,
        "aptCategories": 1 
    };

    model:McrSessionData ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}

// HELPERS ............................................................................................................

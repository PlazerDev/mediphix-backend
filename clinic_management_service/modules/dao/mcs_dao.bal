import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;
import ballerina/log;




public function mcsGetUserIdByEmail(string email) returns string|error|model:InternalError {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection userCollection = check mediphixDb->getCollection("user");

    map<json> filter = {"email":email};
    map<json> projection = {
        "_id": {"$toString": "$_id"}
    
    };

    model:McsUserID|mongodb:Error? findResults = userCollection->findOne(filter, {}, projection);
    io:println("IN DAO -> RESULT: ",findResults);

    
    if findResults is model:McsUserID {
        return findResults._id;
    }
    else {
        model:ErrorDetails errorDetails = {
            message: "Internal Error",
            details: "Error occurred while retrieving MCS ID",
            timeStamp: time:utcNow()
        };
        model:InternalError userNotFound = {body: errorDetails};

        return userNotFound;
    }
}

public function mcsGetAssignedSessionIdList(string userId) returns model:McsAssignedSessionIdList|mongodb:Error ? {    
    mongodb:Collection mcsCollection = check initDatabaseConnection("medical_center_staff");

    map<json> filter = {"userId": userId};
    map<json> projection = {
        "assignedSessions": 1,
        "_id": 0 
    };

    model:McsAssignedSessionIdList ? result = check mcsCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetAssignedSessionDetails(string sessionId) returns model:McsAssignedSession|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = {
        "_id": {"$oid": sessionId },
        "overallSessionStatus": "ACTIVE"
        };

    map<json> projection = {
        "_id": 0,
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1
    };

    model:McsAssignedSession ? result = check sessionCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetDoctorDetailsByID(string doctorId) returns model:McsDoctorDetails|mongodb:Error ?{
    mongodb:Collection doctorCollection = check initDatabaseConnection("doctor");

    map<json> filter = {
        "_id": {"$oid": doctorId }
        };

    map<json> projection = {
        "_id": 0,
        "name": 1,
        "profilePhoto": {"$toString": "$profileImage"},
        "education": 1,
        "specialization": 1
    };

    model:McsDoctorDetails ? result = check doctorCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetOngoingSessionDetails(string sessionId) returns model:McsAssignedSession|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> | error filter = initOngoingSessionFilter(sessionId);
    if filter is error {
        log:printInfo("filter is error");
        return null;
    }

    map<json> projection = {
        "_id": {"$toString": "$_id"},
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1,
        "overallSessionStatus": 1
    };

    model:McsAssignedSession ? result = check sessionCollection->findOne(filter, {}, projection);
    return result;
}

public function mcsGetOngoingSessionTimeSlotDetails(string sessionId) returns model:McsTimeSlotList|mongodb:Error ? {    
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
    io:println("hello this in here");

    map<json> | error filter = initOngoingSessionFilter(sessionId);
    if filter is error {
        return null;
    }

    map<json> projection = {
        "_id": 0,
        "timeSlots": 1
    };

    model:McsTimeSlotList ? result = check sessionCollection->findOne(filter, {}, projection);
    return result;
}

// get specific time slot data by {slotId}
public function mcsGetTimeSlot(string sessionId, int slotId) returns model:McsTimeSlot|mongodb:Error ?{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    map<json> projection = {
        "_id": 0,
        "timeSlots": 1
    };

    model:McsTimeSlotList ? result = check sessionCollection->findOne(filter, {}, projection);
    
    return result is null ? result : ((result.timeSlots.length() > slotId && slotId >= 0) ? result.timeSlots[slotId] : null);
}

// get all timeslot list
public function mcsGetAllTimeSlotList(string sessionId) returns model:McsTimeSlotList|mongodb:Error ?{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    map<json> projection = {
        "_id": 0,
        "timeSlots": 1
    };

    model:McsTimeSlotList ? result = check sessionCollection->findOne(filter, {}, projection);
    
    return result;
}

// get all session details by id - New
public function mcsGetAllSessionData(string sessionId) returns model:McsSession|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

   map<json> projection = {
        "_id": 0,
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "medicalCenterId": 1,
        "aptCategories": 1,
        "payment": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1,
        "overallSessionStatus": 1,
        "timeSlots": 1
    };

    model:McsSession ? result = check sessionCollection->findOne(filter, {}, projection);
    
    return result;
}

// get all session details by id - Old
public function mcsGetAllSessionDetails(string sessionId) returns model:McsAssignedSession|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");

    
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    map<json> projection = {
        "_id": 0,
        "timeSlots": 1,
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1,
        "overallSessionStatus": 1
    };

    model:McsAssignedSession ? result = check sessionCollection->findOne(filter, {}, projection);
    
    return result;
}

// Update the appointment status by the {aptNumber} - Also check the prevStatus is there 
public function mcsUpdateAptStatus(int aptNumber, string newStatus, string preStatus) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection appointmentCollection = check initDatabaseConnection("appointment");

    map<json> filter = {
        "aptNumber": aptNumber,
        "aptStatus": preStatus
    };

    mongodb:Update update = {
        "set": { "aptStatus": newStatus }
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check appointmentCollection->updateOne(filter, update, options);
    return result;
}

// update the {queueOperations} by the {sessionId} and {slotID}
public function mcsUpdateQueueOperations(string sessionId, int slotId, model:McsTimeSlot[]? data) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
  
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    mongodb:Update update = {
        "set": { "timeSlots": data }
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check sessionCollection->updateOne(filter, update, options);
    return result;
}

// update the {overallSessionStatus, status} to "ONGOING" , "STARTED"
public function mcsUpdateSessionToStartAppointment(string sessionId, model:McsTimeSlot[] timeSlot) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
  
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    mongodb:Update update = {
        "set": { "timeSlots": timeSlot, "overallSessionStatus": "ONGOING" }
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check sessionCollection->updateOne(filter, update, options);
    return result;
}

// update the statues of appointments List 
public function mcsUpdateAptListStatus(int[] aptList, string status) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection appointmentCollection = check initDatabaseConnection("appointment");
    
    map<json> filter = {
        "aptNumber": {"$in": aptList}
    };

    mongodb:Update update = {
        "set": { "aptStatus": status }
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check appointmentCollection->updateMany(filter, update, options);
    return result;
}

// update the status of the timeslot
public function mcsUpdateTimeSlotStatus(string sessionId, model:McsTimeSlot[] timeSlot) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
  
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    mongodb:Update update = {
        "set": { "timeSlots": timeSlot, "overallSessionStatus": "ONGOING" }
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check sessionCollection->updateOne(filter, update, options);
    return result;
}

// update the the timeslot
public function mcsUpdateTimeSlot(string sessionId, model:McsTimeSlot[] timeSlot) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
  
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    mongodb:Update update = {
        "set": { "timeSlots": timeSlot}
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check sessionCollection->updateOne(filter, update, options);
    return result;
}

// update the {overallSessionStatus, status} to "OVER" , "FINISHED"
public function mcsUpdateSessionToEndAppointment(string sessionId, model:McsTimeSlot[] timeSlot) returns mongodb:Error|mongodb:UpdateResult{
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
  
    map<json> filter = {
        "_id": {"$oid": sessionId}
    };

    mongodb:Update update = {
        "set": { "timeSlots": timeSlot, "overallSessionStatus": "OVER" }
    };

    mongodb:UpdateOptions options = {};    

    mongodb:UpdateResult|mongodb:Error result = check sessionCollection->updateOne(filter, update, options);
    return result;
}


public function mcsGetAllSessionDataWithDoctorData(string sessionId) returns model:McsSessionWithDoctorDetails|mongodb:Error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("session");
    mongodb:Collection doctorCollection = check initDatabaseConnection("doctor");

    map<json> sessionFilter = {
        "_id": {"$oid": sessionId}
    };

    map<json> sessionProjection = {
        "_id": 0,
        "endTimestamp": 1,
        "startTimestamp": 1,
        "doctorId": 1,
        "hallNumber": 1,
        "noteFromCenter": 1,
        "noteFromDoctor": 1
    };

    model:McsAssignedSession ? sessionResult = check sessionCollection->findOne(sessionFilter, {}, sessionProjection);

    if sessionResult is model:McsAssignedSession {
        map<json> doctorFilter = {
            "_id": {"$oid": sessionResult.doctorId }
            };

        map<json> doctorProjection = {
            "_id": 0,
            "name": 1,
            "profilePhoto": {"$toString": "$profileImage"},
            "education": 1,
            "specialization": 1
        };
        model:McsDoctorDetails ? doctorResult = check doctorCollection->findOne(doctorFilter, {}, doctorProjection);

        if doctorResult is model:McsDoctorDetails {
            model:McsSessionWithDoctorDetails result = {
                doctorName: doctorResult.name,
                endTimestamp: sessionResult.endTimestamp,
                startTimestamp: sessionResult.startTimestamp
            };
            return result;
        }else{
            return null;
        }
    }else {
        return null;
    }
}




// HELPERS ............................................................................................................
public function initDatabaseConnection(string collectionName) returns mongodb:Collection|mongodb:Error {
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.ahaoy.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection collection = check mediphixDb->getCollection(collectionName);
    return collection;
}

public function initOngoingSessionFilter(string sessionId) returns map<json> | error {
    log:printInfo("In the filter");
    time:Civil currentTimeStamp = getCurrentCivilLKTime();
    time:Utc currentTimeStampInUTC = check time:utcFromCivil(currentTimeStamp);

    json currentTimeJson = currentTimeStamp.toJson();
    json hourAfterTimeJson = time:utcToCivil(time:utcAddSeconds(currentTimeStampInUTC, 3600)).toJson();
    
    log:printInfo("currentTimeJson", currentTimeJson=currentTimeJson);
    log:printInfo("hourAfterTimeJson", hourAfterTimeJson=hourAfterTimeJson);

    map<json> filter = {
        "_id": {"$oid": sessionId},
        "$or": [
            {"overallSessionStatus": "ONGOING"},
            {
                "$and": [
                    {"startTimestamp": {"$lte": currentTimeJson}},
                    {"endTimestamp": {"$gte": currentTimeJson}}
                ]
            },
            {
                "$and": [
                    {"startTimestamp": {"$lte": hourAfterTimeJson}},
                    {"endTimestamp": {"$gte": hourAfterTimeJson}}
                ]
            }
        ]
    };

    return filter;
}

public function getCurrentCivilLKTime() returns time:Civil {
    time:Utc utcNow = time:utcNow();
    time:Seconds offsetInSeconds = (5 * 60 * 60) + (30 * 60);
    time:Utc sriLankaUtcTime = time:utcAddSeconds(utcNow, offsetInSeconds);
    time:Civil sriLankaTime = time:utcToCivil(sriLankaUtcTime);
    return sriLankaTime;
}
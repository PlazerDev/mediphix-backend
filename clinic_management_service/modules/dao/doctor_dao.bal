import clinic_management_service.model;
import ballerina/time;
import ballerinax/mongodb;
import ballerina/io;

public function getSessionDetails(string mobile) returns error|model:InternalError|model:Sessions[]{    
    mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection sessionCollection = check mediphixDb->getCollection("session");

    // //ineed send some dummey data to test the function 
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


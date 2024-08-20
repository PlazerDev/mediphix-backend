import clinic_management_service.model;

// import ballerina/io;
import ballerina/time;
import ballerinax/mongodb;

public function savePatient(model:Patient patient) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");

    // Patient patient = {
    //     mobile_number: "0787654321",
    //     first_name: "Kavindi",
    //     last_name: "Ranathunga",
    //     nic: "987654321V",
    //     birthday: "1999-05-15",
    //     email: "kavindirana@gmail.com",
    //     address: {
    //         house_number: "56/7",
    //         street: "Temple Road",
    //         city: "Mount Lavinia",
    //         province: "Western",
    //         postal_code: "10370"
    //     },
    //     allergies: ["Pollen", "Dust"],
    //     special_notes: ["Requires follow-up on previous condition", "Has a history of asthma"]
    // };

    if (patientCollection is mongodb:Collection) {
        check patientCollection->insertOne(patient);
    }
}

public function getPatientByMobile(string mobile) returns model:Patient|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    map<json> filter = {"mobile_number": mobile};
    model:Patient|error? findResults = check patientCollection->findOne(filter, {}, (), model:Patient);
    if findResults !is model:Patient {
        model:ErrorDetails errorDetails = {
            message: string `Failed to find user with mobile number ${mobile}`,
            details: string `patient/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};

        return userNotFound;
    }
    return findResults;
}

public function getPatientByEmail(string email) returns model:Patient|model:NotFoundError|error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("patient");
    map<json> filter = {"email": email};
    model:Patient|error? findResults = check patientCollection->findOne(filter, {}, (), model:Patient);
    if findResults !is model:Patient {
        model:ErrorDetails errorDetails = {
            message: string `Failed to find user with email ${email}`,
            details: string `patient/${email}`,
            timeStamp: time:utcNow()
        };
        model:NotFoundError userNotFound = {body: errorDetails};

        return userNotFound;
    }
    return findResults;
}

public function getAppointments(string mobile) returns model:Appointment[]|error|model:ReturnResponse {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection appointmentCollection = check mediphixDb->getCollection("appointment");
    map<json> filter = {
        "patientMobile": mobile,
        "status": "ACTIVE"
    };
    mongodb:FindOptions findOptions = {
        sort: {"appointmentDate": 1} // Sort by appointmentDate in ascending order
    };
    stream<model:Appointment, error?>|error? findResults = appointmentCollection->find(filter, findOptions, (), model:Appointment);

    if findResults is stream<model:Appointment, error?> {
        model:Appointment[]|error appointments = from model:Appointment appointment in findResults
            select appointment;
        return appointments;

    }

    else {
        model:ReturnResponse returnResponse = {
            message: "Database error occurred",
            statusCode: 500
        };
        return returnResponse;
    }

}


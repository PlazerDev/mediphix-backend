// import ballerina/http;
import ballerina/io;
import ballerinax/mongodb;

mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

public function reg() returns stream<User, error?>|error {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("users");
    stream<User, error?> findResult = check patientCollection->find();
    return findResult;
}

public function save(User user) returns error? {
    mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
    mongodb:Collection patientCollection = check mediphixDb->getCollection("users");
    check patientCollection->insertOne(user);
}

public function patientRegistration(PatientSignupData data) returns error? {
    

}

// service /testing on new http:Listener(9092) {

//     resource function get user() returns User[]|error {

//         mongodb:Database mediphixDb = check mongoDb->getDatabase(string `${database}`);
//         mongodb:Collection patientCollection = check mediphixDb->getCollection("users");
//         stream<User, error?> findResult = check patientCollection->find();
//         return from User m in check findResult
//             select m;

//     }

// }

function saveOnAsgardio() {
    io:println("Save on Asgardio");
}

function registerPatient() {

}

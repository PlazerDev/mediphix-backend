import ballerinax/mongodb;

configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable string cluster = ?;

function savepatient(Patient patient) returns error? {



mongodb:Client mongoDb = check new (connection = string `mongodb+srv://${username}:${password}@${cluster}.v5scrud.mongodb.net/?retryWrites=true&w=majority&appName=${cluster}`);

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

check patientCollection->insertOne(patient);
}

public function main() returns error? {

}

function checkMobileNo(string mobile) {

}

import ballerina/io;
import ballerina/http;


service / on new http:Listener(9001) {

    resource function get patient/appointments(string id) returns http:Response|error? {
        io:println("Hello this is patient appointments.");

        
        return;
    }

    resource function post patient/registration(string id) returns http:Response|error? {
        io:println("Hello this is patient registration.");
        boolean response=registration(id);
        if(response){
            http:Response res2 = 
        }

        
        return;
    }

}


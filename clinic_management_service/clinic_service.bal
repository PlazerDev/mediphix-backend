import ballerina/io;
import ballerina/http;

service / on new http:Listener(9001) {

    resource function get patient/appointments(string id) returns http:Response|error? {
        io:println("Hello this is patient appointments.");

        
        return;
    }

}


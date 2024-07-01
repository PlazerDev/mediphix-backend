import ballerina/http;
import ballerina/io;


http:Client patientEndpoint = check new ("http://localhost:9001",
    timeout = 30,
    retryConfig = {
        interval: 5,
        count: 3
    }, followRedirects = {
        enabled: true,
        maxCount: 5
    }
);


service / on new http:Listener(9000) {


    resource function get mediphix/patient(http:Request req) returns http:Response|error? {
        io:println("Inside get method of mediphix/patient");
        

        http:Response clientResp = check patientEndpoint->/patient/appointments.get();
        return clientResp;
    }

}


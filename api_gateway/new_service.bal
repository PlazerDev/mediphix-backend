import ballerina/http;
import ballerina/log;
import ballerina/io;

// Define the backend services
http:Client patientService = check new("http://localhost:9001");
http:Client doctorService = check new("http://localhost:9003");
http:Client defaultService = check new("http://localhost:9002");

// Define the listener for the API Gateway
listener http:Listener apiGatewayListener = new(9098);

service / on apiGatewayListener {

    // Proxy /shopping requests to shopping service
    resource function 'default [string... path](http:Caller caller, http:Request req) returns error? {
        io:println(path.toString());
        string pathSegment = path.string:'join("/");
        if (pathSegment.startsWith("shopping")) {
            var backendResponse = shoppingService->forward(pathSegment, req);
            if (backendResponse is http:Response) {
                check caller->respond(backendResponse);
            } else {
                check caller->respond(http:Response{statusCode: 500, reasonPhrase: "Internal Server Error"});
            }
        } else if (pathSegment.startsWith("customer")) {
            // Proxy /customer requests to customer service
            var backendResponse = customerService->forward(pathSegment, req);
            if (backendResponse is http:Response) {
                check caller->respond(backendResponse);
            } else {
                check caller->respond(http:Response{statusCode: 500, reasonPhrase: "Internal Server Error"});
            }
        } else {
            // Proxy all other requests to default service
            var backendResponse = defaultService->forward(pathSegment, req);
            if (backendResponse is http:Response) {
                check caller->respond(backendResponse);
            } else {
                check caller->respond(http:Response{statusCode: 500, reasonPhrase: "Internal Server Error"});
            }
        }
    }
}

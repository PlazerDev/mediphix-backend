import laboratory_management_service.'service;
import laboratory_management_service.model;

import ballerina/http;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service / on new http:Listener(9091) {
        
        // Get laboratory with email
    resource function get lab/[string email]() returns http:Response|error? {
        model:Lab|model:ValueError|model:NotFoundError|model:InternalError lab = 'service:getLabByEmail(email.trim());

        http:Response response = new;
        if lab is model:Lab {
            response.statusCode = 200;
            response.setJsonPayload(lab.toJson());
        } else if lab is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(lab.body.toJson());
        } else if lab is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(lab.body.toJson());
        } else if lab is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(lab.body.toJson());
        }
        return response;
    }

}

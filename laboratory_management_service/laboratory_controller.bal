import laboratory_management_service.'service;
import laboratory_management_service.model;

import ballerina/http;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service / on new http:Listener(9091) {
        
}

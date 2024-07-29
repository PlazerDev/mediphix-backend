import appointment_management_service.'service;
import appointment_management_service.model;

import ballerina/http;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service / on new http:Listener(9091) {
    resource function post appointment(model:NewAppointment newAppointment) returns http:Response|error {
        http:Created|model:InternalError appointmentCreationStatus = 'service:createAppointment(newAppointment);
        http:Response response = new;

        if appointmentCreationStatus is http:Created {
            response.statusCode = 201;
            response.setJsonPayload({message: "Appointment created successfully"});
            return response;
        } else if appointmentCreationStatus is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(appointmentCreationStatus.body.toJson());
        }

        return response;
    }

    resource function get appointments/[string mobile]() returns http:Response|error {
        model:Appointment[]|model:InternalError|model:UserNotFound|model:ValueError appointments = 'service:getAppointmentsByMobile(mobile);

        http:Response response = new;
        if appointments is model:Appointment[] {
            response.statusCode = 200;
            response.setJsonPayload(appointments.toJson());
        } else if appointments is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(appointments.body.toJson());
        } else if appointments is model:UserNotFound {
            response.statusCode = 404;
            response.setJsonPayload(appointments.body.toJson());
        } else if appointments is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(appointments.body.toJson());
        } else {
            response.statusCode = 500;
            response.setJsonPayload({message: "Internal server error"});
        }

        return response;
    }
}

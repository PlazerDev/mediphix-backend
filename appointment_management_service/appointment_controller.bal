import appointment_management_service.'service;
import appointment_management_service.model;

import ballerina/http;

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
}

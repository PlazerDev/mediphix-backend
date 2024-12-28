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
        http:Created|model:InternalError appointmentCreationStatus = check 'service:createAppointment(newAppointment);
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

    resource function get appointments/[string userId]() returns http:Response|error {
        model:Appointment[]|model:InternalError|model:NotFoundError|model:ValueError|error? appointments = 'service:getAppointmentsByUserId(userId);

        http:Response response = new;
        if appointments is model:Appointment[] {
            response.statusCode = 200;
            response.setJsonPayload(appointments.toJson());
        } else if appointments is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(appointments.body.toJson());
        } else if appointments is model:NotFoundError {
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
 
    resource function get appointmentsByDoctorId/[string userId]() returns http:Response|error {
        model:Appointment[]|model:InternalError|model:NotFoundError|model:ValueError|error? appointments = 'service:getAppointmentsByDoctorId(userId);

        http:Response response = new;
        if appointments is model:Appointment[] {
            response.statusCode = 200;
            response.setJsonPayload(appointments.toJson());
        } else if appointments is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(appointments.body.toJson());
        } else if appointments is model:NotFoundError {
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
    resource function put appointment/status/[string mobile]/[int appointmentNumber]/[model:AppointmentStatus status]() returns http:Response|error {
        http:Ok|model:InternalError|model:ValueError|model:NotFoundError|error appointmentUpdateStatus = 'service:updateAppointmentStatus(mobile, appointmentNumber, status);

        http:Response response = new;
        if appointmentUpdateStatus is http:Ok {
            response.statusCode = 200;
            response.setJsonPayload({message: "Appointment status updated successfully"});
        } else if appointmentUpdateStatus is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(appointmentUpdateStatus.body.toJson());
        }else if appointmentUpdateStatus is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(appointmentUpdateStatus.body.toJson());
        } else if appointmentUpdateStatus is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(appointmentUpdateStatus.body.toJson());
        } else {
            response.statusCode = 500;
            response.setJsonPayload({message: "Internal server error"});
        }

        return response;
    }

    resource function patch appointments/[int aptNumber]/medicalRecord(model:TempMedicalRecord tempRecord)
     returns http:Response|error {
        http:Ok|model:InternalError|model:NotFoundError|model:ValueError|error? result = 'service:updateMedicalRecord(aptNumber, tempRecord);

        http:Response response = new;
        if result is http:Ok {
            response.statusCode = 200;
            response.setJsonPayload({message: "Appointment medical record updated successfully"});
        } else if result is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        } else if result is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        } else if result is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(result.body.toJson());
        } else {
            response.statusCode = 500;
            response.setJsonPayload({message: "Internal server error"});
        }

        return response;
    }
}

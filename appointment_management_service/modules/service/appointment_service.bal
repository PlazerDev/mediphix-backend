import appointment_management_service.dao;
import appointment_management_service.model;

import ballerina/http;
import ballerina/time;

public function createAppointment(model:NewAppointment newAppointment) returns http:Created|model:InternalError {
    // Get the next appointment number
    int|model:InternalError|error nextAppointmentNumber = dao:getNextAppointmentNumber();
    int newAppointmentNumber = 0;

    if nextAppointmentNumber is int {
        newAppointmentNumber = nextAppointmentNumber;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: "appointment/counter",
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

    // Create a new appointment
    model:Appointment appointment = {
        appointmentNumber: newAppointmentNumber,
        doctorEmail: newAppointment.doctorEmail,
        patientMobile: newAppointment.patientMobile,
        hospital: newAppointment.hospital,
        paid: newAppointment.paid,
        status: "ACTIVE",
        appointmentDate: newAppointment.appointmentDate,
        appointmentTime: newAppointment.appointmentTime,
        createdDate: time:utcNow(),
        lastModifiedDate: time:utcNow()
    };

    http:Created|error? appointmentResult = dao:createAppointment(appointment);
    if appointmentResult is http:Created {
        return http:CREATED;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${newAppointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

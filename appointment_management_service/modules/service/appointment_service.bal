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
        appointmentTime: newAppointment.appointmentTime
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

public function getAppointmentsByMobile(string mobile) returns model:Appointment[]|model:InternalError|model:UserNotFound|model:ValueError {
    if (mobile.length() === 0 || mobile.length() !== 10) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid mobile number",
            details: string `appointment/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    model:Appointment[]|model:InternalError|model:UserNotFound|error? appointments = dao:getAppointmentsByMobile(mobile);
    if appointments is model:Appointment[] {
        return appointments;
    } else if appointments is model:InternalError {
        return appointments;
    } else if appointments is model:UserNotFound {
        return appointments;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

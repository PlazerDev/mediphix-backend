import appointment_management_service.dao;
import appointment_management_service.model;

import ballerina/http;
import ballerina/io;
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

    model:AppointmentStatus appointmentStatus = "ACTIVE";

    if (newAppointment.paid) {
        appointmentStatus = "PAID";
    }

    // Create a new appointment
    model:Appointment appointment = {
        appointmentNumber: newAppointmentNumber,
        doctorEmail: newAppointment.doctorEmail,
        patientMobile: newAppointment.patientMobile,
        doctorSessionId: newAppointment.doctorSessionId,
        category: newAppointment.category,
        hospital: newAppointment.hospital,
        paid: newAppointment.paid,
        status: appointmentStatus,
        appointmentDate: newAppointment.appointmentDate,
        appointmentTime: newAppointment.appointmentTime,
        createdTime: time:utcToCivil(time:utcNow()),
        lastModifiedTime: time:utcToCivil(time:utcNow())
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

public function getAppointmentsByMobile(string mobile) returns model:Appointment[]|model:InternalError|model:NotFoundError|model:ValueError|error {
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

    model:Appointment[]|model:InternalError|model:NotFoundError|error? appointments = dao:getAppointmentsByMobile(mobile);
    if appointments is model:Appointment[] {
        return appointments;
    } else if appointments is model:InternalError {
        return appointments;
    } else if appointments is model:NotFoundError {
        return appointments;
    } else {
        io:println(appointments);
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${mobile}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getAppointmentByMobileAndNumber(string mobile, string appointmentNumber) returns model:Appointment|model:InternalError|model:NotFoundError|model:ValueError|error {
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

    if (appointmentNumber.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid appointment number",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    model:Appointment|model:InternalError|model:NotFoundError|error? appointment = dao:getAppointmentByMobileAndNumber(mobile, appointmentNumber);
    if appointment is model:Appointment {
        return appointment;
    } else if appointment is model:InternalError {
        return appointment;
    } else if appointment is model:NotFoundError {
        return appointment;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

public function updateAppointmentStatus(string mobile, int appointmentNumber, model:AppointmentStatus status) returns http:Ok|model:InternalError|model:NotFoundError|model:ValueError|error {
    if (mobile.length() === 0 || mobile.length() !== 10) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid mobile number",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    if (appointmentNumber === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid appointment number",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    http:Ok|model:InternalError|model:NotFoundError|error? updateResult = dao:updateAppointmentStatus(mobile, appointmentNumber, status);

    if updateResult is http:Ok {
        return http:OK;
    } else if updateResult is model:InternalError|model:NotFoundError {
        return updateResult;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${mobile}/${appointmentNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

import appointment_management_service.dao;
import appointment_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/time;

public function createAppointmentRecord(model:NewAppointmentRecord newAppointmentRecord) returns model:AppointmentResponse|model:InternalError|error? {
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

    model:Payment payment = {
        isPaid: false,
        amount: newAppointmentRecord.paymentAmount,
        handleBy: "",
        paymentTimestamp: () 
    };

    model:AppointmentRecord appointmentRecord = {
        aptNumber: newAppointmentNumber,
        sessionId: newAppointmentRecord.sessionId,
        timeSlot: newAppointmentRecord.timeSlot,
        aptCategories: newAppointmentRecord.aptCategories,       
        patientId: newAppointmentRecord.patientId,
        patientName: newAppointmentRecord.patientName,
        queueNumber: newAppointmentRecord.queueNumber, 
        doctorId: newAppointmentRecord.doctorId,
        payment: payment,
        doctorName: newAppointmentRecord.doctorName,
        medicalCenterId: newAppointmentRecord.medicalCenterId,
        medicalCenterName: newAppointmentRecord.medicalCenterName,
        aptCreatedTimestamp: time:utcToCivil(time:utcAddSeconds(time:utcNow(), 5 * 3600 + 30 * 60)),
        aptStatus: "ACTIVE"
    };

    model:AppointmentResponse|error? appointmentResult = dao:createAppointmentRecord(appointmentRecord);
    if (appointmentResult is model:AppointmentResponse) {
        return appointmentResult;
    }

    model:ErrorDetails errorDetails = {
        message: "Unexpected internal error occurred, please retry!",
        details: "Appointment",
        timeStamp: time:utcNow()
    };

    model:InternalError internalError = {body: errorDetails};
    return internalError;
}

public function getAppointmentsByUserId(string userId) returns model:AppointmentRecord[]|model:InternalError|model:NotFoundError|model:ValueError|error {
    if (userId.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid mobile number",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    model:AppointmentRecord[]|model:InternalError|model:NotFoundError|error? appointments = dao:getAppointmentsByUserId(userId);
    if appointments is model:AppointmentRecord[] {
        return appointments;
    } else if appointments is model:InternalError {
        return appointments;
    } else if appointments is model:NotFoundError {
        return appointments;
    } else {
        io:println(appointments);
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getUpcomingAppointmentsByUserId(string userId) returns model:UpcomingAppointment[]|model:InternalError|model:NotFoundError|model:ValueError|error {
    if (userId.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid mobile number",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    model:UpcomingAppointment[]|model:InternalError|model:NotFoundError|error? appointments = dao:getUpcomingAppointmentsByUserId(userId);
    if appointments is model:UpcomingAppointment[] {
        return appointments;
    } else if appointments is model:InternalError {
        return appointments;
    } else if appointments is model:NotFoundError {
        return appointments;
    } else {
        io:println(appointments);
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getPreviousAppointmentsByUserId(string userId) returns model:AppointmentRecord[]|model:InternalError|model:NotFoundError|model:ValueError|error {
    if (userId.length() === 0) {
        model:ErrorDetails errorDetails = {
            message: "Please provide a valid mobile number",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {
            body: errorDetails
        };
        return valueError;
    }

    model:AppointmentRecord[]|model:InternalError|model:NotFoundError|error? appointments = dao:getPreviousAppointmentsByUserId(userId);
    if appointments is model:AppointmentRecord[] {
        return appointments;
    } else if appointments is model:InternalError {
        return appointments;
    } else if appointments is model:NotFoundError {
        return appointments;
    } else {
        io:println(appointments);
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/${userId}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }

}

public function getSessionDetailsByDoctorId(string doctorId) returns 
model:Session[]|model:InternalError|model:NotFoundError|model:ValueError|error {

    model:Session[]|model:InternalError|model:NotFoundError|error? sessions = 
    dao:getSessionDetailsByDoctorId(doctorId);
    if sessions is model:Session[] {
        return sessions;
    } else if sessions is model:InternalError {
        return sessions;
    } else if sessions is model:NotFoundError {
        return sessions;
    } else {
        io:println(sessions);
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `appointment/sessions/${doctorId}`,
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

public function updateMedicalRecord(int aptNumber, model:NewMedicalRecord tempRecord)
returns http:Ok|model:InternalError|model:NotFoundError|model:ValueError|error {

    // Create final MedicalRecord with converted timestamps
    model:MedicalRecord medicalRecord = {
        aptNumber: tempRecord.aptNumber,
        startedTimestamp: check time:civilFromString(tempRecord.startedTimestamp),
        endedTimestamp: check time:civilFromString(tempRecord.endedTimestamp),
        symptoms: tempRecord.symptoms,
        diagnosis: tempRecord.diagnosis,
        treatments: tempRecord.treatments,
        noteToPatient: tempRecord.noteToPatient,
        isLabReportRequired: tempRecord.isLabReportRequired,
        labReport: ()
    };
    // Handle optional labReport and its optional reportDetails
    // if tempRecord.labReport != () {
    //     // Create initial LabReport without reportDetails
    //     LabReport labReport = {
    //         requestedTimestamp: check time:civilFromString(tempRecord.labReport.requestedTimestamp),
    //         isHighPrioritize: tempRecord.labReport.isHighPrioritize,
    //         testType: tempRecord.labReport.testType,
    //         testName: tempRecord.labReport.testName,
    //         noteToLabStaff: tempRecord.labReport.noteToLabStaff,
    //         status: tempRecord.labReport.status,
    //         reportDetails: () // Initialize as nil
    //     };

    //     // Handle optional reportDetails if present
    //     if tempRecord.labReport.reportDetails != () {
    //         labReport.reportDetails = {
    //             testStartedTimestamp: check time:civilFromString(tempRecord.labReport.reportDetails.testStartedTimestamp),
    //             testEndedTimestamp: check time:civilFromString(tempRecord.labReport.reportDetails.testEndedTimestamp),
    //             additionalNote: tempRecord.labReport.reportDetails.additionalNote,
    //             resultFiles: tempRecord.labReport.reportDetails.resultFiles
    //         };
    //     }

    //     medicalRecord.labReport = labReport;
    // }

    if tempRecord.aptNumber != aptNumber {
        model:ErrorDetails errorDetails = {
            message: "Invalid appointment number",
            details: "Appointment number in URL must match the medical record",
            timeStamp: time:utcNow()
        };
        model:ValueError valueError = {body: errorDetails};
        return valueError;
    }

    http:Ok|model:InternalError|model:NotFoundError|error? updateResult = dao:updateMedicalRecord(medicalRecord);

    if updateResult is http:Ok {
        return http:OK;

        // 
        // if appendQueueNoResult is http:Ok {
        //     return http:OK;
        // }
        // else if appendQueueNoResult is model:InternalError|model:NotFoundError {
        //     return appendQueueNoResult;
        // }
        // else {
        //     model:ErrorDetails errorDetails = {
        //         message: "Unexpected internal error occurred, please retry!",
        //         details: string `Failed to update medical record for appointment/${medicalRecord.aptNumber}`,
        //         timeStamp: time:utcNow()
        //     };
        //     model:InternalError internalError = {body: errorDetails};
        //     return internalError;
        // }

    } else if updateResult is model:InternalError|model:NotFoundError {
        return updateResult;
    } else {
        model:ErrorDetails errorDetails = {
            message: "Unexpected internal error occurred, please retry!",
            details: string `Failed to update medical record for appointment/${medicalRecord.aptNumber}`,
            timeStamp: time:utcNow()
        };
        model:InternalError internalError = {body: errorDetails};
        return internalError;
    }
}

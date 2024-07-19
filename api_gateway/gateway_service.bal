import ballerina/http;
import ballerina/log;

type Doctor record {
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
};

type Patient record {
    string name;
    string dob;
    string address;
    string phone;
    string email;
};

type Appointment record {
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean paid;
    string appointmentDate;
};

type PatientWithCardNo record {
    *Patient;
    string cardNo;
};

type ReservationRequest record {
    PatientWithCardNo patient;
    string doctor;
    string hospital_id;
    string hospital;
    string appointment_date;
};

type Fee record {
    string patientName;
    string doctorName;
    string actualFee;
};

type ReservationStatus record {
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID;
    string status;
};

configurable string appointmentManagementService = "http://localhost:9090";
configurable string paymentManagementService = "http://localhost:9090/healthcare/payments";

final http:Client appointmentServicesEndpoint = check new (appointmentManagementService);
final http:Client paymentEndpoint = check new (paymentManagementService);

service /mediphix on new http:Listener(9000) {
    resource function post categorys/[string category]/reserve(ReservationRequest payload) returns ReservationStatus|http:NotFound|http:InternalServerError {
        PatientWithCardNo patient = payload.patient;
        Appointment|http:ClientError appointment = appointmentServicesEndpoint->/[payload.hospital_id]/categorys/[category]/reserve.post({
            patient: {
                name: patient.name,
                dob: patient.dob,
                address: patient.address,
                phone: patient.phone,
                email: patient.email
            },
            doctor: payload.doctor,
            hospital: payload.hospital,
            appointment_date: payload.appointment_date
        });

        if appointment !is Appointment {
            log:printError("Appointment reservation failed.", appointment);
            if appointment is http:ClientRequestError {
                return <http:NotFound>{body: "unknown hospital,doctor or category"};
            }
            return <http:InternalServerError>{body: appointment.message()};
        }
        int appointmentNumber = appointment.appointmentNumber;

        Fee|http:ClientError fee = appointmentServicesEndpoint->/[payload.hospital_id]/categories/appointments/[appointmentNumber]/fee;

        if fee !is Fee {
            log:printError("Retrieving fee failed", fee);
            if fee is http:ClientRequestError {
                return <http:NotFound>{body: "unknown appointment ID"};
            }
            return <http:InternalServerError>{body: fee.message()};
        }
        decimal|error actualFee = decimal:fromString(fee.actualFee);
        if actualFee is error {
            return <http:InternalServerError>{body: "fee retrieval failed"};
        }

        ReservationStatus|http:ClientError status = paymentEndpoint->/.post({
            appointmentNumber,
            doctor: appointment.doctor,
            patient: appointment.patient,
            fee: fee.actualFee,
            confirmed: false,
            card_number: patient.cardNo
        });

        if status !is ReservationStatus {
            log:printError("Payment failed", status);
            if status is http:ClientRequestError {
                return <http:NotFound>{body: string `unknown appointment ID`};
            }
            return <http:InternalServerError>{body: status.message()};
        }
        return status;
    }

}

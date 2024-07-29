import ballerina/http;
// import ballerina/log;
import ballerina/io;

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

final http:Client clinicServiceEP = check new ("http://localhost:9090",
    retryConfig = {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    }
);
final http:Client appointmentServiceEP = check new ("http://localhost:9091",
    retryConfig = {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    }
);

configurable string issuer = ?;
configurable string audience = ?;
configurable string jwksUrl = ?;

listener http:Listener httpListener = check new (9000);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
    // ,
    // auth: [
    //     {
    //         jwtValidatorConfig: {
    //             issuer: issuer,
    //             audience: audience,
    //             signatureConfig: {
    //                 jwksConfig: {
    //                     url: jwksUrl
    //                 }
    //             }
    //         },
    //         scopes: ["insert_appointment", "retrieve_own_patient_data"]
    //     }
    // ]
}
service /patient on httpListener {

    // @http:ResourceConfig {
    //     // "insert_appointment" scope is required to invoke this resource
    //     auth: {
    //         scopes: ["insert_appointment"]
    //     }
    // }
    resource function get bymobile(string mobile) returns http:Response|error? {
        io:println("Inside Appointment");
        http:Response|error? appointments = check appointmentServiceEP->/appointments/[mobile];
        io:println(appointments);
        return appointments;
    }

}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    },
    auth: [
        {
            jwtValidatorConfig: {
                issuer: issuer,
                audience: audience,
                signatureConfig: {
                    jwksConfig: {
                        url: jwksUrl
                    }
                }
            },
            scopes: ["insert_appointment", "retrieve_own_patient_data"]
        }
    ]
}
service /doctor on httpListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["insert_appointment", "retrieve_own_patient_data"]
        }
    }
    resource function get categorys/reserve(http:Request request) returns string|error? {
        io:println("Inside Appointment");
        json|http:ClientError patient = request.getJsonPayload();

        io:println("Patient: ", patient);

        return "Appointment Reserved Successfully";
    }

}

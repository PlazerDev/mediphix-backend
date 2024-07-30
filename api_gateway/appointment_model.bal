
public enum AppointmentStatus {
    ACTIVE,
    PAID,
    INQUEUE,
    ONGOING,
    OVER,
    CANCELLED
};

public type NewAppointment record {
    string doctorEmail;
    string patientMobile;
    string hospital;
    boolean paid;
    string appointmentDate;
    string appointmentTime;
};

public type Appointment record {
    int appointmentNumber;
    string doctorEmail;
    string patientMobile;
    string hospital;
    boolean paid;
    AppointmentStatus status;
    string appointmentDate;
    string appointmentTime;
};

public type AppointmentNumberCounter record {
    string _id;
    int sequence_value;
};
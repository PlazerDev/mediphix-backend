import ballerina/time;

public enum AppointmentStatus {
    ACTIVE,
    PAID,
    INQUEUE,
    ONGOING,
    OVER,
    CANCELLED
};

public enum AppointmentCategory {
    GENERAL_MEDICINE,
    CARDIOLOGY,
    ORTHOPEDICS,
    PEDIATRICS,
    GYNECOLOGY_OBSTETRICS,
    DERMATOLOGY,
    ENT,
    NEUROLOGY,
    GASTROENTEROLOGY,
    PULMONOLOGY,
    ONCOLOGY,
    ENDOCRINOLOGY,
    NEPHROLOGY,
    UROLOGY,
    PSYCHIATRY_MENTAL_HEALTH,
    OPHTHALMOLOGY,
    DENTISTRY,
    PHYSICAL_THERAPY_REHABILITATION,
    ALLERGY_IMMUNOLOGY,
    RADIOLOGY,
    GERIATRICS,
    EMERGENCY_MEDICINE,
    OCCUPATIONAL_HEALTH
};

public type NewAppointment record {
    string doctorEmail;
    string patientMobile;
    int doctorSessionId;
    AppointmentCategory category;
    string hospital;
    boolean paid;
    string appointmentDate;
    string appointmentTime;
};

public type Appointment record {
    int appointmentNumber;
    string doctorMobile;
    string patientMobile;
    int sessionId;
    string category;
    int medicalCenterId;
    string medicalCenterName;
    boolean isPaid;
    decimal payment;
    AppointmentStatus status;
    time:Date appointmentTime;
    time:Date createdTime;
    time:Date lastModifiedTime;
};

public type AppointmentNumberCounter record {
    string _id;
    int sequence_value;
};

public  type Session record {
    int sessionNumber;
    string medicalCenterName;
    string doctorEmail;
    string hospital;
    string appointmentDate;
    string appointmentTime;
    AppointmentCategory category;
    string medicalCenterMobile;
};

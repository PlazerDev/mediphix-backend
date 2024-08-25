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

// public enum AppointmentCategory {
//     PRIMARY_CARE_GENERAL_MEDICINE,
//     PRIMARY_CARE_PEDIATRICS,

//     SPECIALTY_CARE_CARDIOLOGY,
//     SPECIALTY_CARE_ORTHOPEDICS,
//     SPECIALTY_CARE_NEUROLOGY,
//     SPECIALTY_CARE_PULMONOLOGY,
//     SPECIALTY_CARE_GASTROENTEROLOGY,
//     SPECIALTY_CARE_ENDOCRINOLOGY,
//     SPECIALTY_CARE_NEPHROLOGY,
//     SPECIALTY_CARE_UROLOGY,
//     SPECIALTY_CARE_ONCOLOGY,
//     SPECIALTY_CARE_DERMATOLOGY,

//     WOMENS_HEALTH_GYNECOLOGY_OBSTETRICS,

//     MENTAL_HEALTH_PSYCHIATRY,
//     MENTAL_HEALTH_PSYCHOLOGY,

//     SURGICAL_CARE_GENERAL_SURGERY,
//     SURGICAL_CARE_SPECIALIZED_SURGERY,
//     SURGICAL_CARE_PLASTIC_RECONSTRUCTIVE_SURGERY,

//     DIAGNOSTICS_IMAGING_RADIOLOGY,
//     DIAGNOSTICS_IMAGING_LABORATORY_MEDICINE,

//     EMERGENCY_ACUTE_CARE_EMERGENCY_MEDICINE,
//     EMERGENCY_ACUTE_CARE_CRITICAL_CARE,

//     PREVENTIVE_WELLNESS_OCCUPATIONAL_HEALTH,
//     PREVENTIVE_WELLNESS_PREVENTIVE_MEDICINE,
//     PREVENTIVE_WELLNESS_GERIATRICS,

//     REHABILITATION_PHYSICAL_THERAPY,
//     REHABILITATION_REHABILITATION,

//     SPECIALIZED_CARE_ENT,
//     SPECIALIZED_CARE_OPHTHALMOLOGY,
//     SPECIALIZED_CARE_DENTISTRY,
//     SPECIALIZED_CARE_ALLERGY_IMMUNOLOGY
// }

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
    string doctorEmail;
    string patientMobile;
    int doctorSessionId;
    AppointmentCategory category;
    string hospital;
    boolean paid;
    AppointmentStatus status;
    string appointmentDate;
    string appointmentTime;
    time:Date createdTime;
    time:Date lastModifiedTime;
};

public type AppointmentNumberCounter record {
    string _id;
    int sequence_value;
};


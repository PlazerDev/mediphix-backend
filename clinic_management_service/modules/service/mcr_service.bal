import clinic_management_service.model;
import clinic_management_service.dao;
import ballerinax/mongodb;
import ballerina/time;


// get the [userId] by [email]
public function mcrGetUserIdByEmail(string email) returns error|string|model:InternalError {
    error|string|model:InternalError result = check dao:mcrGetUserIdByEmail(email);
    return result;
}


public function mcrSearchPayment(int aptNumber) returns error|model:NotFoundError|model:McrSearchPaymentFinalData {

    model:McrAppointment|mongodb:Error ? aptDetails = dao:mcrGetAptDetails(aptNumber);

    if aptDetails is model:McrAppointment{
        model:McrPatientData|mongodb:Error ? patientDetails = dao:mcrGetPatientDetails(aptDetails.patientId);

        if patientDetails is model:McrPatientData {
            model:McrDoctorData|mongodb:Error ? doctorDetails = dao:mcrGetDoctorDetails(aptDetails.doctorId);
            
            if doctorDetails is model:McrDoctorData {
                model:McrSessionData|mongodb:Error ? sessionDetails = dao:mcrGetSessionDetails(aptDetails.sessionId);
                
                if sessionDetails is model:McrSessionData {

                    time:Date[] startAndEndTimeOfSlot = getStartEndTimeOfSlot(sessionDetails.startTimestamp, aptDetails.timeSlot);
                    
                    model:McrSearchPaymentFinalData result = {
                        doctorDetails: {
                            profileImage: doctorDetails.profileImage, 
                            name: doctorDetails.name, 
                            mobile: doctorDetails.mobile, 
                            education: doctorDetails.education,
                            specialization: doctorDetails.specialization
                        },
                        patientDetails: {
                            profileImage: patientDetails.profileImage,
                            name: patientDetails.first_name + " " + patientDetails.last_name, 
                            age: calculateAgeFromBirthday(patientDetails.birthday)
                        },
                        aptAndSessionDetails: {
                            aptNumber: aptNumber, 
                            aptCategories: sessionDetails.aptCategories, 
                            aptStatus: aptDetails.aptStatus, 
                            startTimestamp: startAndEndTimeOfSlot[0], 
                            endTimestamp: startAndEndTimeOfSlot[1], 
                            hallNumber: sessionDetails.hallNumber, 
                            queueNumber: aptDetails.queueNumber, 
                            noteFromCenter: sessionDetails.noteFromCenter, 
                            noteFromDoctor: sessionDetails.noteFromDoctor,
                            aptCreatedTimestamp: aptDetails.aptCreatedTimestamp
                        },
                        paymentDetails: {
                            isPayed: false, 
                            paymentTimestamp: aptDetails.payment.paymentTimestamp, 
                            handleBy: aptDetails.payment.handleBy, 
                            amount: aptDetails.payment.amount}
                    };

                    return result;
                }else if sessionDetails is null {
                    return initNotFoundError("Session details not found!");
                }else {
                    return initDatabaseError(sessionDetails);
                }

            }else if doctorDetails is null {
                return initNotFoundError("Doctor details not found!");
            }else {
                return initDatabaseError(doctorDetails);
            }

        }else if  patientDetails is null {
            return initNotFoundError("Patient details not found!");
        }else {
            return initDatabaseError(patientDetails);
        }

    }else if  aptDetails is null {
        return initNotFoundError("Appointment details not found!");
    }else {
        // case :: database error
        return initDatabaseError(aptDetails);
    }
    
}

// Helpers ......................................................................................................................

public function initDatabaseError(mongodb:Error err) returns error{
    return error("Database error occured! : ",  err);
}

public function getStartEndTimeOfSlot(time:Date sessionStartTimestamp, int slotId) returns time:Date[] {
     
    time:Date startTime = sessionStartTimestamp.clone();
    time:Date endTime = sessionStartTimestamp.clone();

    startTime.hour = startTime.hour + slotId - 1;
    endTime.hour = startTime.hour + 1;
    
    return [startTime, endTime];
}

public function calculateAgeFromBirthday(string birthday) returns string {
    time:Utc | time:Error bday = time:utcFromString(birthday + "T00:00:00.00+05:30");

    if bday is time:Utc {
        time:Civil timeNow = time:utcToCivil(time:utcNow());
        time:Civil temp = time:utcToCivil(bday);
        int age = timeNow.year - temp.year;
        return age.toString();
    }else {
        return "N/A";
    }
}

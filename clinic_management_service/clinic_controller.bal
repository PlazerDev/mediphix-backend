import clinic_management_service.'service;
import clinic_management_service.model;

import ballerina/http;
import ballerina/io;
import ballerina/log;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]

    }
}
service / on new http:Listener(9090) {

    // patient

    // registration
    resource function post signup/patient(model:PatientSignupData data) returns http:Response|model:ReturnMsg|error? {
        io:println("Inside clinic controller", data); // comment
        model:ReturnMsg result = 'service:registerPatient(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Patient Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/doctor(model:DoctorSignupData data) returns http:Response|model:ReturnMsg|error? {
        model:ReturnMsg result = 'service:registerDoctor(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Doctor Registered Successfully"});
        }

        io:println(result);
        return (response);
    }

    resource function post signup/medicalCenter(model:MedicalCenterSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Medical Center");

        model:ReturnMsg result = 'service:registerMedicalCenter(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Medical Center Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/MedicalCenterStaff(model:MedicalCenterStaffData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Medical Center");

        model:ReturnMsg result = 'service:registerMedicalCenterStaff(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Medical Center Staff Registered  Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/registerMedicalCenterReceptionist(model:MedicalCenterReceptionistSignupData data) returns http:Response|model:ReturnMsg|error? {

        model:ReturnMsg result = 'service:registerMedicalCenterReceptionist(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Medical Center Receptionist Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/registerMedicalCenterLabStaff(model:MedicalCenterLabStaffSignupData data) returns http:Response|model:ReturnMsg|error? {

        model:ReturnMsg result = 'service:registerMedicalCenterLabStaff(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Medical Center Lab Staff Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    resource function post signup/laboratary(model:otherSignupData data) returns http:Response|model:ReturnMsg|error? {

        io:println("Hello this is Laboratary");

        model:ReturnMsg result = 'service:registerLaboratary(data);

        http:Response response = new;
        if (result.statusCode == 500 || result.statusCode == 400) {
            response.statusCode = result.statusCode;
            response.setJsonPayload({message: result.message});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({message: "Laboratary Registered Successfully"});
        }

        io:println(result);
        return (response);

    }

    // resource function post signup/MedicalCenterAdmin(model:otherSignupData data) returns http:Response|model:ReturnMsg|error? {

    //     io:println("Hello this is Medical Center");

    //     model:ReturnMsg result = 'service:registerMedicalCenter(data);

    //     http:Response response = new;
    //     if (result.statusCode == 500 || result.statusCode == 400) {
    //         response.statusCode = result.statusCode;
    //         response.setJsonPayload({message: result.message});
    //     } else {
    //         response.statusCode = 200;
    //         response.setJsonPayload({message: "Medical Center Registered Successfully"});
    //     }

    //     io:println(result);
    //     return (response);

    // }

    // Get patient with user id
    resource function get patient/[string userId]() returns http:Response|error? {
        model:Patient|model:ValueError|model:NotFoundError|model:InternalError patient = 'service:getPatientById(userId.trim());
        http:Response response = new;
        if patient is model:Patient {
            response.statusCode = 200;
            response.setJsonPayload(patient.toJson());
        } else if patient is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(patient.body.toJson());
        } else if patient is model:NotFoundError {
            response.statusCode = 404;
            response.setJsonPayload(patient.body.toJson());
        } else if patient is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(patient.body.toJson());
        }
        return response;
    }

    // Get patient with email
    resource function get patientIdByEmail/[string email]() returns string|error? {
        model:Patient|model:ValueError|model:NotFoundError|model:InternalError patient = 'service:getPatientByEmail(email.trim());
        if patient is model:Patient {
            return patient._id;
        } else {
            return error("Error occurred while retrieving patient id number");
        }
    }

    //get doctor name by email
    resource function get doctorIdByEmail/[string email]() returns string|error? {
        error|string|model:InternalError doctor = 'service:doctorIdByEmail(email.trim());
        if doctor is string {
            return doctor;
        } else {
            return error("Error occurred while retrieving doctor id number");
        }
    }

    // Get appointments of a patient
    resource function get appointments(string mobile) returns http:Response|error {
        model:Appointment[]|model:ReturnResponse appointments = check 'service:getAppointments(mobile);

        http:Response response = new;
        if appointments is model:Appointment[] {
            response.statusCode = 200;
            response.setJsonPayload(appointments.toJson());
        } else if appointments is model:ReturnResponse {
            response.statusCode = appointments.statusCode;
            response.setJsonPayload(appointments.toJson());
        }
        io:println(appointments);
        return response;
    }

    //Doctor Controllers 

    //Get all doctor details
    resource function get getAllDoctors() returns http:Response|error? {
        model:Doctor[]|model:InternalError doctorDetails = check 'service:getAllDoctors();
        http:Response response = new;
        if doctorDetails is model:Doctor[] {
            response.statusCode = 200;
            response.setJsonPayload(doctorDetails.toJson());
        } else if doctorDetails is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(doctorDetails.body.toJson());
        }
        return response;
    }

    resource function get getSessionDetailsByDoctorId/[string doctorId]() returns http:Response|error? {
        model:Session[]|model:InternalError session = check 'service:getSessionDetailsByDoctorId(doctorId);

        http:Response response = new;
        if session is model:Session[] {
            response.statusCode = 200;
            response.setJsonPayload(session.toJson());
            io:println("Function responde successfully");
        } else if (session is model:InternalError) {
            response.statusCode = 500;
            response.setJsonPayload(session.body.toJson());
        }
        return response;

    }

    // Get doctor details by id
    resource function get getDoctorDetails/[string id]() returns error|http:Response {
        model:Doctor|model:InternalError doctorDetails = check 'service:getDoctorDetails(id.trim());

        http:Response response = new;
        if (doctorDetails is model:Doctor) {
            response.statusCode = 200;
            response.setJsonPayload(doctorDetails);
        } else {
            response.statusCode = 404;
            response.setJsonPayload({message: "Doctor not found"});
        }
        return response;
    }

    resource function get getDoctorDetails2/[string id]() returns error|http:Response {
        model:Doctor|model:InternalError doctorDetails = check 'service:getDoctorDetails2(id.trim());

        io:println(doctorDetails);

        http:Response response = new;
        if (doctorDetails is model:Doctor) {
            response.statusCode = 200;
            response.setJsonPayload(doctorDetails);
        } else {
            response.statusCode = 404;
            response.setJsonPayload({message: "Doctor not found"});
        }
        return response;
    }

    //this function return doctor details

    resource function get getAllMedicalCenters() returns http:Response|error? {
        model:MedicalCenter[]|model:InternalError medicalCenters = check 'service:getAllMedicalCenters();
        http:Response response = new;
        if medicalCenters is model:MedicalCenter[] {
            response.statusCode = 200;
            response.setJsonPayload(medicalCenters.toJson());
        } else if medicalCenters is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(medicalCenters.body.toJson());
        }
        return response;
    }

    resource function post setDoctorJoinRequest/[string userId]/[string medicalCenterId]() returns http:Response|error? {
        model:DoctorMedicalCenterRequest request = {
            doctorId: userId,
            medicalCenterId: medicalCenterId,
            verified: false
        };
        http:Created|error? result = check 'service:setDoctorJoinRequest(request);
        http:Response response = new;
        if (result is http:Created) {
            response.statusCode = 200;
        }
        else {
            response.statusCode = 500;
        }

    }

    //get my medical centers
    resource function get getMyMedicalCenters/[string userId]() returns error|http:Response {
        model:MedicalCenter[]|model:InternalError medicalCenters = check 'service:getMyMedicalCenters(userId.trim());
        http:Response response = new;
        if medicalCenters is model:MedicalCenter[] {
            response.statusCode = 200;
            response.setJsonPayload(medicalCenters.toJson());
        } else if medicalCenters is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(medicalCenters.body.toJson());
        }
        return response;
    }

    resource function get getDoctorSessionVacancies/[string userId]() returns error|http:Response {
        model:SessionVacancy[]|model:InternalError sessionVacancies = check 'service:getDoctorSessionVacancies(userId.trim());
        http:Response response = new;
        if sessionVacancies is model:SessionVacancy[] {
            response.statusCode = 200;
            response.setJsonPayload(sessionVacancies.toJson());
        } else if sessionVacancies is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(sessionVacancies.body.toJson());
        }
        return response;
    }

    resource function post respondDoctorToSessionVacancy(model:NewDoctorResponse newDoctorResponse) returns http:Response|error? {
        http:Created|model:InternalError|error? result = check 'service:respondDoctorToSessionVacancy(newDoctorResponse);
        http:Response response = new;
        if (result is http:Created) {
            response.statusCode = 200;
            response.setJsonPayload({message: "Doctor response submitted successfully"});
        } else if (result is model:InternalError) {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        } else {
            response.statusCode = 500;
            response.setJsonPayload({message: "Internal server error!"});
        }
        return response;
    }

    // MCS [START] ###################################################################

    // #### GET USERID BY EMAIL OF THE MCS 
    resource function get mcsIdByEmail/[string email]() returns string|error? {
        error|string|model:InternalError userId = 'service:mcsGetUserIdByEmail(email.trim());
        if userId is string {
            return userId;
        } else {
            return error("Error occurred while retrieving MCS id number");
        }
    }

    // #### VIEW ALL ASSIGNED UPOMMING SESSIONS OF THE MCS 
    resource function get mcsUpcomingClinicSessions/[string userId]() returns http:Response|error {

        model:NotFoundError|model:McsAssignedSessionWithDoctorDetails[] result = check 'service:mcsGetUpcomingSessionList(userId);

        http:Response response = new;

        if (result is model:McsAssignedSessionWithDoctorDetails[]) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    // #### VIEW ALL ASSIGNED Ongoing SESSIONS OF THE MCS 
    resource function get mcsOngoingClinicSessions/[string userId]() returns http:Response|error {

        // within start time & end time
        // before 1 hour

        model:NotFoundError|model:McsAssignedSessionWithDoctorDetails[] result = check 'service:mcsGetOngoingSessionList(userId);

        http:Response response = new;

        if (result is model:McsAssignedSessionWithDoctorDetails[]) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    // #### VIEW ALL ASSIGNED Ongoing TIME SLOT DATA OF THE MCS 
    resource function get mcsOngoingClinicSessionTimeSlots/[string sessionId]() returns http:Response|error {

        model:NotFoundError|model:McsTimeSlotList result = check 'service:mcsGetOngoingSessionTimeSlotDetails(sessionId);

        http:Response response = new;

        if (result is model:McsTimeSlotList) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsStartAppointment(string sessionId, int slotId, string userId) returns http:Response|error {

        model:NotFoundError|model:McsTimeSlot result = check 'service:mcsStartAppointment(sessionId, slotId, userId);

        http:Response response = new;

        if (result is model:McsTimeSlot) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsStartTimeSlot(string sessionId, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcsStartTimeSlot(sessionId, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload({"status": "sucess"});
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsEndTimeSlot(string sessionId, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcsEndTimeSlot(sessionId, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload({"status": "sucess"});
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsEndLastTimeSlot(string sessionId, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcsEndLastTimeSlot(sessionId, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload({"status": "sucess"});
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsMoveToAbsent(string sessionId, int slotId, int aptNumber, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcsMoveToAbsent(sessionId, slotId, aptNumber, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsRevertFromAbsent(string sessionId, int slotId, int aptNumber, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcsRevertFromAbsent(sessionId, slotId, aptNumber, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcsAddToEnd(string sessionId, int slotId, int aptNumber, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcsAddToEnd(sessionId, slotId, aptNumber, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    // MCS [END]  ###################################################################

    // ******************************************************************************************************

    // MCR [START] ###################################################################  

    resource function get mcrIdByEmail/[string email]() returns string|error? {
        error|string|model:InternalError userId = 'service:mcrGetUserIdByEmail(email.trim());
        if userId is string {
            return userId;
        } else {
            return error("Error occurred while retrieving MCR id number");
        }
    }

    resource function get mcrSearchPayment/[int aptNumber]/[string userId]() returns http:Response|error {

        model:NotFoundError|model:McrSearchPaymentFinalData result = check 'service:mcrSearchPayment(aptNumber);
        // TODO :: by using the userId check the currosponding aptNumber is in the same medical center. 
        http:Response response = new;

        if (result is model:McrSearchPaymentFinalData) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcrMarkToPay(int aptNumber, string userId) returns http:Response|error {

        model:NotFoundError? result = check 'service:mcrMarkToPay(aptNumber, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    // MCR [END] ###################################################################

    // ******************************************************************************************************

    // ROLE [START] ###################################################################  

    resource function get findUserRole/[string userEmail]() returns http:Response|error {

        model:NotFoundError|model:ValueError|model:FinalUserResult result = check 'service:findUserRole(userEmail);

        http:Response response = new;
        if (result is model:FinalUserResult) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        } else if result is model:ValueError {
            response.statusCode = 406;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    // ROLE [END] ###################################################################  

    
    resource function get mcaIdByEmail/[string email]() returns string|error? {
        error|string|model:InternalError userId = 'service:mcaGetUserIdByEmail(email.trim());
        if userId is string {
            return userId;
        } else {
            return error("Error occurred while retrieving MCA id number");
        }
    }

    resource function get mcaGetMCSdata/[string userId]() returns http:Response|error {

        model:NotFoundError|model:McsFinalUserDataWithAssignedSession[] result = check 'service:mcaGetMCSdata(userId);
        http:Response response = new;

        if (result is model:McsFinalUserDataWithAssignedSession[]) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

     resource function get mcsGetActiveSessions/[string userId]() returns http:Response|error {

        model:NotFoundError|model:McsSessionWithDoctorDetails[] result = check 'service:mcsGetActiveSessions(userId);
        http:Response response = new;

        if (result is model:McsSessionWithDoctorDetails[]) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function get mcaGetMCRdata/[string userId]() returns http:Response|error {

        model:NotFoundError|model:MedicalCenterReceptionist[] result = check 'service:mcaGetMCRdata(userId);
        http:Response response = new;

        if (result is model:MedicalCenterReceptionist[]) {
            response.statusCode = 200;
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404;
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function put mcaAssignSession(string sessionId,string mcsId, string userId) returns http:Response|error {
       
        model:NotFoundError ? result = check 'service:mcaAssignSession(sessionId, mcsId, userId);

        http:Response response = new;

        if (result is null) {
            response.statusCode = 200; 
            response.setJsonPayload(result.toJson());
        } else if (result is model:NotFoundError) {
            response.statusCode = 404; 
            response.setJsonPayload(result.body.toJson());
        }

        return response;
    }

    resource function post uploadmedia/[string userType]/[string uploadType]/[string emailHead]/[string fileName]/[string fileType]/[string extension](byte[] fileBytes) returns http:Response|error? {
        io:println("Upload media function called");
        string|model:InternalError|error? result = 'service:uploadMedia(userType, uploadType, emailHead, fileBytes, fileName, fileType, extension);
        http:Response response = new;
        if (result is string) {
            io:println("Media uploaded successfully ", result);
            response.statusCode = 200;
            response.setJsonPayload({message: "Media uploaded successfully"});
        } else if (result is model:InternalError) {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        }
        return response;

    }

    resource function get media/[string userType]/[string uploadType]/[string email]() returns http:Response|error? {
        io:println("Get media function called");
        stream<byte[], io:Error?>|model:InternalError|error? result = 'service:getMedia(userType, uploadType, email);

        if (result is stream<byte[], io:Error?>) {
            io:println("Media retrieved");
            http:Response response = new;
            response.setPayload(result);
            return response;
        } else if (result is model:InternalError) {
            http:Response response = new;
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
            return response;
        } else {
            return error("Error occurred while retrieving media");
        }
    }

    resource function get medialink/[string userType]/[string uploadType]/[string email]() returns http:Response|error? {
        io:println("Get media function called");
        string|error? result = 'service:getMediaLink(userType, uploadType, email);

        if (result is string) {
            io:println("Media retrieved");
            http:Response response = new;
            json jsonResponse = {"mediaLink": result};
            response.setJsonPayload(jsonResponse);
            return response;
        } else if (result is error) {
            http:Response response = new;
            response.statusCode = 500;
            response.setJsonPayload({"message": result.message()});
            return response;
        } else {
            return error("Error occurred while retrieving media");
        }
    }

    resource function post createSessionVacancy(model:NewSessionVacancy newSessionVacancy) returns http:Response {
        http:Created|model:InternalError|error? result = 'service:createSessionVacancy(newSessionVacancy);

        http:Response response = new;
        if (result is http:Created) {
            response.statusCode = 200;
            response.setJsonPayload({"message": "Session vacancy created"});
        } else if (result is model:InternalError) {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        } else {
            response.statusCode = 500;
            response.setJsonPayload({"message": "Internal server error!"});
        }
        return response;
    }

    // MCA -----------------------------------------------------------------------------------------------
    resource function get getMcaSessionVacancies/[string userId]() returns error|http:Response {
        io:println("in clinic controller before service call");
        model:SessionVacancy[]|model:InternalError sessionVacancies = check 'service:getMcaSessionVacancies(userId.trim());
        io:println("in clinic controller after service call");
        http:Response response = new;
        if sessionVacancies is model:SessionVacancy[] {
            log:printInfo("Session vacancy retrieval successful");
            response.statusCode = 200;
            response.setJsonPayload(sessionVacancies.toJson());
        } else if sessionVacancies is model:InternalError {
            io:println("in clinic controller sessionVacancies is model:InternalError");
            response.statusCode = 500;
            response.setJsonPayload(sessionVacancies.body.toJson());
        }
        return response;
    }

    resource function patch mcaAcceptDoctorResponseApplicationToOpenSession/[string sessionVacancyId]/[int responseId]/[int appliedOpenSessionId]() returns http:Response|error {
        http:Ok|model:InternalError|error? result = check 'service:mcaAcceptDoctorResponseApplicationToOpenSession(sessionVacancyId, responseId, appliedOpenSessionId);

        http:Response response = new;
        if result is http:Ok {
            response.statusCode = 200;
            response.setJsonPayload({message: "Doctor response accepted successfully"});
        } else if result is model:InternalError {
            response.statusCode = 500;
            response.setJsonPayload(result.body.toJson());
        } else {
            response.statusCode = 500;
            response.setJsonPayload({message: "Internal server error!"});
        }

        return response;

    }
}


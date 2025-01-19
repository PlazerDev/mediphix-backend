import clinic_management_service.model;
import ballerinax/mongodb;
import ballerina/io;


  # Fetch user data from given user email
    # 
    # 
    # + email - userEmail
    # + return - on sucess email, userId, role

public function getUserData(string email) returns model:User|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("user");

    map<json> filter = {
        "email": email
    };

   map<json> projection = {
        "_id": {"$toString": "$_id"},
        "email": 1,
        "role": 1
    };

    model:User ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center admin info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, profileImage, medicalCernterEmail, userId

public function getInfoMCA(string userId) returns model:MedicalCenterAdmin|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center_admin");

    map<json> filter = {
        "userId": userId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "profileImage": 1,
        "medicalCenterEmail": 1,
        "userId": 1
    };

    model:MedicalCenterAdmin ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center staff info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCS(string userId) returns model:MedicalCenterStaff|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center_staff");

    map<json> filter = {
        "userId": userId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "empId": 1,
        "profileImage": 1,
        "centerId": 1,
        "userId": 1
    };

    model:MedicalCenterStaff ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center receptionist info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCR(string userId) returns model:MedicalCenterReceptionist|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center_receptionist");

    map<json> filter = {
        "userId": userId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "empId": 1,
        "profileImage": 1,
        "centerId": 1,
        "userId": 1
    };

    model:MedicalCenterReceptionist ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center labstaff info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCLS(string userId) returns model:MedicalCenterLabStaff|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center_lab_staff");

    map<json> filter = {
        "userId": userId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "empId": 1,
        "profileImage": 1,
        "centerId": 1,
        "userId": 1
    };

    model:MedicalCenterLabStaff ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center deatils info by center id
    # 
    # 
    # + centerId - center ID
    # + return - on sucess return name, profileImage and centerId

public function getInfoCenter(string centerId) returns model:MedicalCenterBrief|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center");

    map<json> filter = {
        "_id": {"$oid": centerId}
    };

   map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "profileImage": 1
    };

    model:MedicalCenterBrief ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center deatils info by center email
    # 
    # 
    # + centerEmail - center ID
    # + return -  on sucess return name, profileImage and centerId

public function getInfoCenterByEmail(string centerEmail) returns model:MedicalCenterBrief|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center");

    map<json> filter = {
        "email": centerEmail
    };

   map<json> projection = {
        "_id": {"$toString": "$_id"},
        "name": 1,
        "profileImage": 1
    };

    model:MedicalCenterBrief ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch all center staff info by medical center ID
    # 
    # 
    # + centerId - center ID
    # + return - on sucess return list of name, nic, mobile, empId, centerId, profileImage, userId, assignedSessions

public function getInfoMCSByCenterId(string centerId) returns model:MedicalCenterStaff[]|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center_staff");

    map<json> filter = {
        "centerId": centerId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "empId": 1,
        "profileImage": 1,
        "centerId": 1,
        "userId": 1,
        "assignedSessions": 1
    };

    stream<model:MedicalCenterStaff, error?> result = check collection->find(filter, {}, projection, model:MedicalCenterStaff);
    
    model:MedicalCenterStaff[]|error finalResult = from model:MedicalCenterStaff userData in result select userData;
    if finalResult is model:MedicalCenterStaff[] {
        return finalResult;
    } else {
        return null;
    }
}



  # Fetch all center receptionist info by medical center ID
    # 
    # 
    # + centerId - center ID
    # + return - on sucess return list of name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCRByCenterId(string centerId) returns model:MedicalCenterReceptionist[]|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center_receptionist");

    map<json> filter = {
        "centerId": centerId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "empId": 1,
        "profileImage": 1,
        "centerId": 1,
        "userId": 1
    };

    stream<model:MedicalCenterReceptionist, error?> result = check collection->find(filter, {}, projection, model:MedicalCenterReceptionist);
    model:MedicalCenterReceptionist[]|error finalResult = from model:MedicalCenterReceptionist userData in result select userData;
    if finalResult is model:MedicalCenterReceptionist[] {
        return finalResult;
    } else {
        return null;
    }
}


  # Fetch center staff info by userId (with assign session list)
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCSWithAssignedSession(string userId) returns model:MedicalCenterStaff|mongodb:Error ? {
    io:println("In DAO", userId);
    mongodb:Collection collection = check initDatabaseConnection("medical_center_staff");

    map<json> filter = {
        "userId": userId
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "nic": 1,
        "mobile": 1,
        "empId": 1,
        "profileImage": 1,
        "centerId": 1,
        "userId": 1,
        "assignedSessions": 1
    };

    model:MedicalCenterStaff ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Update the assigned session list in MCS
    # 
    # 
    # + userId - user id of the medical center staff
    # + assignedSessionList - new assigned session list
    # + return - on sucess return null
public function updateAssignedSessionList(string userId, string[] assignedSessionList) returns mongodb:Error|error ? {
    mongodb:Collection sessionCollection = check initDatabaseConnection("medical_center_staff");
  
    map<json> filter = {
        "userId": userId
    };

    mongodb:Update update = {
        "set": { "assignedSessions": assignedSessionList}
    };

    mongodb:UpdateOptions options = {};    
    mongodb:UpdateResult result = check sessionCollection->updateOne(filter, update, options);

    if result.modifiedCount > 0 {
        return null;
    } 
}
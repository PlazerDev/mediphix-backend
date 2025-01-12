import clinic_management_service.model;
import ballerinax/mongodb;


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

public function getInfoMCA(string userId) returns model:medicalCenterAdmin|mongodb:Error ? {
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

    model:medicalCenterAdmin ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center staff info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCS(string userId) returns model:medicalCenterStaff|mongodb:Error ? {
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

    model:medicalCenterStaff ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center receptionist info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCR(string userId) returns model:medicalCenterReceptionist|mongodb:Error ? {
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

    model:medicalCenterReceptionist ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center labstaff info by userId
    # 
    # 
    # + userId - user ID
    # + return - on sucess return name, nic, mobile, empId, centerId, profileImage, userId

public function getInfoMCLS(string userId) returns model:medicalCenterLabStaff|mongodb:Error ? {
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

    model:medicalCenterLabStaff ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}


  # Fetch center deatils info by center id
    # 
    # 
    # + centerId - center ID
    # + return - on sucess return name, profileImage

public function getInfoCenter(string centerId) returns model:MedicalCenterBrief|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center");

    map<json> filter = {
        "_id": {"$oid": centerId}
    };

   map<json> projection = {
        "_id": 0,
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
    # + return -  on sucess return name, profileImage

public function getInfoCenterByEmail(string centerEmail) returns model:MedicalCenterBrief|mongodb:Error ? {
    mongodb:Collection collection = check initDatabaseConnection("medical_center");

    map<json> filter = {
        "email": centerEmail
    };

   map<json> projection = {
        "_id": 0,
        "name": 1,
        "profileImage": 1
    };

    model:MedicalCenterBrief ? result = check collection->findOne(filter, {}, projection);
    
    return result;
}
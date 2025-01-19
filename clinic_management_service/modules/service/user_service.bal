import clinic_management_service.dao;
import clinic_management_service.model;
import ballerinax/mongodb;
public function findUserRole(string userEmail) returns error|model:NotFoundError|model:ValueError|model:FinalUserResult {
    model:User|mongodb:Error ? userData = dao:getUserData(userEmail);

    if userData is model:User {
        if userData.role == "MCA" {
            // case :: role is MCA
            model:MedicalCenterAdmin|mongodb:Error ? mcaData = dao:getInfoMCA(<string> userData._id);
            if mcaData is model:MedicalCenterAdmin {
                model:MedicalCenterBrief|mongodb:Error ? centerData = dao:getInfoCenterByEmail(mcaData.medicalCenterEmail);
                if centerData is model:MedicalCenterBrief {
                    model:FinalUserResult result = {
                        userData: mcaData,
                        medicalCenterData: centerData,
                        role: "MCA"
                    };
                    return result;
                }else if centerData is null {
                    return initNotFoundError("Medical center data not found");
                }else {
                    return initDatabaseError(centerData);
                }
            }else if mcaData is null {
                return initNotFoundError("User specifc data not found");
            }else {
                return initDatabaseError(mcaData);
            }
        }else if userData.role == "MCS" {
            // case :: role is MCS
            model:MedicalCenterStaff|mongodb:Error ? mcsData = dao:getInfoMCS(<string> userData._id);
            if mcsData is model:MedicalCenterStaff {
                model:MedicalCenterBrief|mongodb:Error ? centerData = dao:getInfoCenter(mcsData.centerId);
                if centerData is model:MedicalCenterBrief {
                    model:FinalUserResult result = {
                        userData: mcsData,
                        medicalCenterData: centerData,
                        role: "MCS"
                    };
                    return result;
                }else if centerData is null {
                    return initNotFoundError("Medical center data not found");
                }else {
                    return initDatabaseError(centerData);
                }
            }else if mcsData is null {
                return initNotFoundError("User specifc data not found");
            }else {
                return initDatabaseError(mcsData);
            }
        }else if userData.role == "MCR" {
            // case :: role is MCR
            model:MedicalCenterReceptionist|mongodb:Error ? mcrData = dao:getInfoMCR(<string> userData._id);
            if mcrData is model:MedicalCenterReceptionist {
                model:MedicalCenterBrief|mongodb:Error ? centerData = dao:getInfoCenter(mcrData.centerId);
                if centerData is model:MedicalCenterBrief {
                    model:FinalUserResult result = {
                        userData: mcrData,
                        medicalCenterData: centerData,
                        role: "MCR"
                    };
                    return result;
                }else if centerData is null {
                    return initNotFoundError("Medical center data not found");
                }else {
                    return initDatabaseError(centerData);
                }
            }else if mcrData is null {
                return initNotFoundError("User specifc data not found");
            }else {
                return initDatabaseError(mcrData);
            }
        }else if userData.role == "MCLS"{
            // case :: role is MCLS
            model:MedicalCenterLabStaff|mongodb:Error ? mclsData = dao:getInfoMCLS(<string> userData._id);
            if mclsData is model:MedicalCenterLabStaff {
                model:MedicalCenterBrief|mongodb:Error ? centerData = dao:getInfoCenter(mclsData.centerId);
                if centerData is model:MedicalCenterBrief {
                    model:FinalUserResult result = {
                        userData: mclsData,
                        medicalCenterData: centerData,
                        role: "MCLS"
                    };
                    return result;
                }else if centerData is null {
                    return initNotFoundError("Medical center data not found");
                }else {
                    return initDatabaseError(centerData);
                }
            }else if mclsData is null {
                return initNotFoundError("User specifc data not found");
            }else {
                return initDatabaseError(mclsData);
            }
        }else {
            return initValueError("Invalid user role");
        }
    }else if userData is null {
        return initNotFoundError("User not found");
    }else {
        return initDatabaseError(userData);
    }
}


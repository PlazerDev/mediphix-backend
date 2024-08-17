import ballerina/http;
import ballerina/time;

public type ErrorDetails record {
    string message;
    string details;
    time:Utc timeStamp;
};


public type NotFoundError record {
    *http:NotFound;
    ErrorDetails body;
};

public type UserNotFound record {
    *http:NotFound;
    ErrorDetails body;
};

public type ValueError record {
    *http:NotAcceptable;
    ErrorDetails body;
};

public type InternalError record {
    *http:InternalServerError;
    ErrorDetails body;
};

public type ReturnResponse record {
    string message;
    int statusCode;
    
};


public type Patient record {|
    string mobile_number;
    string first_name;
    string last_name;
    string nic;
    string birthday;
    string email;
    string address;
    string nationality;
    string[] allergies?;
    string[] special_notes?;
|};

public type JWTPayload record {|
    string iss; // Issuer of the token
    string sub; // Subject (typically the user identifier)
    string aud; // Audience (the client ID)
    int exp;    // Expiration time (Unix timestamp)
    int nbf;    // Not before time (Unix timestamp)
    int iat;    // Issued at time (Unix timestamp)
    string jti; // JWT ID (unique identifier for the token)
    string aut; // Authorization type (e.g., APPLICATION_USER)
    string binding_type; // Type of session binding (e.g., sso-session)
    string client_id;    // Client ID
    string azp;          // Authorized party (also client ID)
    string org_id;       // Organization ID
    string scope;        // Scopes granted by the token
    string org_name;     // Organization name
    string binding_ref;  // Binding reference
    string username;     // Username associated with the token
|};

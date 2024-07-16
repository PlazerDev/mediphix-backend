// import ballerina/http;

// import ballerina/io;

public function getUserService() returns stream<User, error?>|error {
    stream<User, error?>|error regResult = reg();
    return regResult;
   
}

// service /testing on new http:Listener(9091){

//     resource function get user() returns User[] |error? {

//         stream<User, error?>|error regResult = reg();
//         return from User m in check regResult
//             select m;

//     }

//     // resource  function post user() returns User[] | error? {
//     //     User user = {mobile_number: "07754234562", role: "patient", password: "1234"};
//     //     error? saveResult = save(user);
//     //     if saveResult is error {
//     //         return saveResult;
//     //     } else {
//     //         return [user];
//     //     }
//     // }
//     resource  function post user(User newUser) returns User[] | error? {

//         error? saveResult = save(newUser);
//         if saveResult is error {
//             return saveResult;
//         } else {
//             return [newUser];
//         }
//     }

// }

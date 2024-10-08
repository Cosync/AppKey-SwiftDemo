//
//  DataModel.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import Foundation

public struct User:Codable {
    var id:String = ""
    var name:String = ""
    var displayName:String = ""
    var handle: String = ""
}

 
struct LoginChallenge:Decodable {
    
     
    var rpId: String
    var challenge:String
    var allowCredentials: [Credential]
    var timeout: Int
    var userVerification: String
    var requireAddPasskey:Bool?
}

struct Credential: Decodable {
    var id:String
    var type:String
}


struct Register: Decodable {
    var status:Bool
    var message: String
    var user: User
}

struct ErrorReturn: Decodable {
    var code:Bool
    var message: String
}



struct SignupChallenge: Decodable {
    var challenge:String
    var user: User
}

struct AttestReponse:Codable {
    var attestationObject:String
    var clientDataJSON:String
}

struct Attestation:Codable {
    var id:String
    var rawId:String?
    var authenticatorAttachment:String?
    var type:String?
    var response:AttestReponse
}


struct Assertion:Codable {
    var id:String
    var rawId:String?
    var authenticatorAttachment:String?
    var type:String?
    var response:AssertResponse
}


struct AssertResponse:Codable {
    var authenticatorData:String
    var clientDataJSON:String
    var signature:String
    var userHandle:String
}

struct AuthenticationInfo:Decodable {
    let newCounter:Int
    let credentialID:String
    let userVerified:Bool
    let credentialDeviceType:String
    let credentialBackedUp:Bool
    let origin:String
    let rpID:String
}


struct Application:Codable {
    let appId:String
    let displayAppId:String
    let name:String
    let userId:String
    let status:String
    let handleType:String
    let emailExtension:Bool
    let appPublicKey:String
    let appToken:String
    let signup:String
    let anonymousLoginEnabled:Bool
    let userNamesEnabled:Bool
    let userJWTExpiration:Int
    let locales:[String]
   
}



struct AppUser:Codable {
    let appUserId:String
    let displayName:String
    let handle:String
    let status:String
    let appId:String
    var accessToken:String?
    var signUpToken:String?
    var jwt:String?
    let userName:String?
    let locale:String?
    let lastLogin: String?
}


struct SignupData:Codable {
     
    let handle:String
    let message:String
    var signUpToken:String?
}




struct Passkey:Codable {
    let id:String
    let publicKey:String
    let counter:Int
    let deviceType:String
    let credentialBackedUp:String
    let name:String
    let platform:String
    let lastUsed: Date
    let createdAt: Date
    let updatedAt: Date
   
}


struct LoginComplete:Decodable {
    let verified:Bool
    let authenticationInfo:AuthenticationInfo
   
}
 

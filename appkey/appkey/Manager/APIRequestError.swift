//
//  APIRequestError.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import Foundation

public enum APIRequestError: Error {
    case cosyncAuthConfiguration
    case invalidAppToken                // 400
    case appNoLongerExist               // 401
    case appSuspended                   // 402
    case missingParameter               // 403
    case accountSuspended               // 404
    case invalidAccessToken             // 405
    case appInviteNotSupported          // 406
    case appSignupNotSupported          // 407
    case appGoogle2FactorNotSupported   // 408
    case appPhone2FactorNotSupported    // 409
    case appUserPhoneNotVerified        // 410
    case expiredSignupCode              // 411
    case phoneNumberInUse               // 412
    case appIsMirgrated                 // 413
    case anonymousLoginNotSupported     // 414
    case appleLoginNotSupported         // 415
    case googleLoginNotSupported        // 416
    case internalServerError            // 500
    case invalidLoginCredentials        // 600
    case handleAlreadyRegistered        // 601
    case invalidData                    // 602
    case accountDoesNotExist            // 603
    case invalidMetaData                // 604
    case userNameAlreadyInUse           // 605
    case appIsNotSupporUserName         // 606
    case userNameDoesNotExist           // 607
    case accountIsNotVerify             // 608
    case invalidLocale                  // 609
    case emailAccountExists             // 610
    case appleAccountExists             // 611
    case googleAccountExists            // 612
    case invalidToken                   // 613
    case passkeyNotExist                // 614
    case invalidPasskey                 // 615
    case accountNoPasskey
    
    public var message: String {
        switch self {
        case .cosyncAuthConfiguration:
            return "invalid api configuration"
        case .invalidAppToken:
            return "invalid app token"
        case .appNoLongerExist:
            return "app no longer exists"
        case .appSuspended:
            return "app is suspended"
        case .missingParameter:
            return "missing parameter"
        case .accountSuspended:
            return "user account is suspended"
        case .invalidAccessToken:
            return "invalid access token"
        case .appInviteNotSupported:
            return "app does not support invite"
        case .appSignupNotSupported:
            return "app does not support signup"
        case .appGoogle2FactorNotSupported:
            return "app does not support google two-factor verification"
        case .appPhone2FactorNotSupported:
            return "app does not support phone two-factor verification"
        case .appUserPhoneNotVerified:
            return "user does not have verified phone number"
        case .expiredSignupCode:
            return "expired signup code"
        case .phoneNumberInUse:
            return "phone number already in use"
        case .internalServerError:
            return "internal server error"
        case .invalidLoginCredentials:
            return "invalid login credentials"
        case .handleAlreadyRegistered:
            return "handle already registered"
        case .invalidData:
            return "invalid data"
        case .accountDoesNotExist:
            return "account does not exist"
        case .invalidMetaData:
            return "invalid metadata"
       
        case .anonymousLoginNotSupported:
            return "app does not support anonymous login"
        case .appIsMirgrated:
            return "app is migrated to other server"
        case .userNameAlreadyInUse:
            return "user name already assigned"
        case .appIsNotSupporUserName:
            return "app does not support username login"
        case .userNameDoesNotExist:
            return "user name deos not exist"
        case .accountIsNotVerify:
            return "account has not been verified"
        case .invalidLocale:
            return "invalid locale"
        case .appleLoginNotSupported:
            return "app does not support Apple Authentication"
        case .googleLoginNotSupported:
            return "app does not support Goole Authentication"
        case .emailAccountExists:
            return "email account already exist"
        case .appleAccountExists:
            return "apple account already exist"
        case .googleAccountExists:
            return "google account already exist"
        case .invalidToken:
            return "token in invalid"
        case .passkeyNotExist:
            return "passkey does not exist"
        case .invalidPasskey:
            return "invalid passkey"
        case .accountNoPasskey:
            return "user does not have passkey"
        }
    }
    
    static func checkResponse(data: Data, response: URLResponse) throws -> Void {
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return
            }
            else if httpResponse.statusCode == 400 {
                if let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] {
                    if let code = json["code"] as? Int {
                        switch code {

                        case 400:
                            throw APIRequestError.invalidAppToken
                        case 401:
                            throw APIRequestError.appNoLongerExist
                        case 402:
                            throw APIRequestError.appSuspended
                        case 403:
                            throw APIRequestError.missingParameter
                        case 404:
                            throw APIRequestError.accountSuspended
                        case 405:
                            throw APIRequestError.invalidAccessToken
                        case 406:
                            throw APIRequestError.appInviteNotSupported
                        case 407:
                            throw APIRequestError.appSignupNotSupported
                        case 408:
                            throw APIRequestError.appGoogle2FactorNotSupported
                        case 409:
                            throw APIRequestError.appPhone2FactorNotSupported
                        case 410:
                            throw APIRequestError.appUserPhoneNotVerified
                        case 411:
                            throw APIRequestError.expiredSignupCode
                        case 412:
                            throw APIRequestError.phoneNumberInUse
                        case 413:
                            throw APIRequestError.appIsMirgrated
                        case 414:
                            throw APIRequestError.anonymousLoginNotSupported
                        case 415:
                            throw APIRequestError.appleLoginNotSupported
                        case 416:
                            throw APIRequestError.googleLoginNotSupported
                        case 500:
                            throw APIRequestError.internalServerError
                        case 600:
                            throw APIRequestError.invalidLoginCredentials
                        case 601:
                            throw APIRequestError.handleAlreadyRegistered
                        case 602:
                            throw APIRequestError.invalidData
                        case 603:
                            throw APIRequestError.accountDoesNotExist
                        case 604:
                            throw APIRequestError.invalidMetaData
                        case 605:
                            throw APIRequestError.userNameAlreadyInUse
                        case 606:
                            throw APIRequestError.appIsNotSupporUserName
                        case 607:
                            throw APIRequestError.userNameDoesNotExist
                        case 608:
                            throw APIRequestError.accountIsNotVerify
                        case 609:
                            throw APIRequestError.invalidLocale
                        case 610:
                            throw APIRequestError.emailAccountExists
                        case 611:
                            throw APIRequestError.appleAccountExists
                        case 612:
                            throw APIRequestError.googleAccountExists
                        case 613:
                            throw APIRequestError.invalidToken
                        case 614:
                            throw APIRequestError.passkeyNotExist
                        case 615:
                            throw APIRequestError.invalidPasskey
                       

                        default:
                            throw APIRequestError.internalServerError
                        }
                    } else {
                        throw APIRequestError.internalServerError
                    }
                } else {
                    throw APIRequestError.internalServerError
                }

            } else if httpResponse.statusCode == 500 {
                throw APIRequestError.internalServerError
            }
        }
        throw APIRequestError.internalServerError
    }
}


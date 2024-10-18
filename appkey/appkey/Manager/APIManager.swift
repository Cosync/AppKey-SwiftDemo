//
//  APIManager.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import Foundation
import os

var API = APIManager.shared

class APIManager:ObservableObject {
    
    static let shared = APIManager()
    
   
    var appUser:AppUser? = nil
    var application:Application? = nil
    var accessToken:String = ""
    let logger = Logger()
    
     
    func getApp() async throws -> Application? {
        
        do {
            guard let url = URL(string: "\(Constants.API_URL_ADDRESS)/api/appuser/app") else {
                throw APIRequestError.invalidData
            }
            
            let defaults = UserDefaults.standard
            let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
            
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = ["app-token": appToken]

            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(from: url)
            try APIRequestError.checkResponse(data: data, response: response)
            
            let app = try JSONDecoder().decode(Application.self, from: data)
            
            self.application = app
           // print(self.application)
            return app
                 
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }

    }
    
    
    func getAppUser(user:AppUser) async throws -> AppUser {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/user"
        
        do {
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
             
            
            let url = URL(string: url)!
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["access-token": self.accessToken]
            urlRequest.httpMethod = "GET"
         
          
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
            
            let result = try JSONDecoder().decode(AppUser.self, from: data)
           
            // print("getAppUser app \(result)")
            self.appUser = result
            
            return result
                 
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
    }
    
    func signup(handle:String, displayName:String, localse:String? = nil) async throws -> SignupChallenge? {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/signup"
        
        do {
            let moddedHandle = handle.replacingOccurrences(of: "+", with: "%2B")
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [URLQueryItem(name: "displayName", value: displayName),
                                                URLQueryItem(name: "handle", value: moddedHandle)]
          
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            let defaults = UserDefaults.standard
            let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["app-token": appToken]
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
            
        
            
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
            
            let result = try JSONDecoder().decode(SignupChallenge.self, from: data)
           
             print("register response \(result)")
            
            return result
                
           
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
       
    }
    
    
    
    func signupComplete(signupToken:String, code:String) async throws -> Bool {
      
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/signupComplete"
        
        do {
           
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [URLQueryItem(name: "code", value: code)]
          
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["signup-token": signupToken]
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
            
        
            
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
            
            var user = try JSONDecoder().decode(AppUser.self, from: data)
            
            if let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] {
                user.accessToken = json["access-token"] as? String
            }
            
           
            self.accessToken = user.accessToken!
            self.appUser = user
            
            return true
           
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
       
    }
    
    func signupConfirm(handle:String, attest:Attestation) async throws -> SignupData {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/signupConfirm"
        do {
            let moddedHandle = handle.replacingOccurrences(of: "+", with: "%2B")
            let attetstRsponse = "{\"attestationObject\": \"\(attest.response.attestationObject)\", \"clientDataJSON\": \"\(attest.response.clientDataJSON)\"}"
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: moddedHandle),
                                                URLQueryItem(name: "id", value: attest.id),
                                                URLQueryItem(name: "response", value: attetstRsponse )
                                                ]
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            
            let defaults = UserDefaults.standard
            let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["app-token": appToken]
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
            
            
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
             
            var signData = try JSONDecoder().decode(SignupData.self, from: data)
            
            if let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] {
                signData.signUpToken = json["signup-token"] as? String
            }
           
           
            return signData
            
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
    }
    
    
    func loginAnonymous(uuidString: String) async throws -> SignupChallenge? {
          
          let url = "\(Constants.API_URL_ADDRESS)/api/appuser/loginAnonymous"
          
          do {

              let handle = "ANON_\(uuidString)"
              
              var requestBodyComponents = URLComponents()
              requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: handle)]
            
              let config = URLSessionConfiguration.default
              let session = URLSession(configuration: config)
              let url = URL(string: url)!
              
              let defaults = UserDefaults.standard
              let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
              
              var urlRequest = URLRequest(url: url)
              urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
              urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
              urlRequest.allHTTPHeaderFields = ["app-token": appToken]
              urlRequest.httpMethod = "POST"
              urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
          
              let (data, response) = try await session.data(for: urlRequest)
              try APIRequestError.checkResponse(data: data, response: response)
              
              // print("loginAnonymous return data \(data.base64URLEncode().base64Decoded()!)")
              
              let result = try JSONDecoder().decode(SignupChallenge.self, from: data)

              // print("login server response \(result)")

              return result
             
          }
            catch let error as APIRequestError {
                print("login error \(error.message)")
                throw error
            }
            catch {
                print("login error \(error.localizedDescription)")
                throw error
            }
    }
    
    
    func loginAnonymousComplete(handle:String, attest:Attestation) async throws -> Bool {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/loginAnonymousComplete"
        do {
            
            let attetstRsponse = "{\"attestationObject\": \"\(attest.response.attestationObject)\", \"clientDataJSON\": \"\(attest.response.clientDataJSON)\"}"
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: handle),
                                                URLQueryItem(name: "id", value: attest.id),
                                                URLQueryItem(name: "response", value: attetstRsponse )
                                                ]
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            
            let defaults = UserDefaults.standard
            let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["app-token": appToken]
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
            
            
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
            
            // print("loginAnonymousComplete data \(data.base64URLEncode().base64Decoded()!)")
            
            
            var user = try JSONDecoder().decode(AppUser.self, from: data)
            
            if let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] {
                user.accessToken = json["access-token"] as? String
            }
            
            
            self.appUser = user
            
            if let accessToken = user.accessToken {
                self.accessToken = accessToken
            }

            return true
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
    }
    
    
    
    func login(handle:String) async throws -> LoginChallenge? {
          
          let url = "\(Constants.API_URL_ADDRESS)/api/appuser/login"
          
          do {
              // your post request data
              let moddedHandle = handle.replacingOccurrences(of: "+", with: "%2B")
              
              var requestBodyComponents = URLComponents()
              requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: moddedHandle)]
            
              let config = URLSessionConfiguration.default
              let session = URLSession(configuration: config)
              let url = URL(string: url)!
              
              
              let defaults = UserDefaults.standard
              let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
              
              var urlRequest = URLRequest(url: url)
              urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
              urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
              urlRequest.allHTTPHeaderFields = ["app-token": appToken]
              urlRequest.httpMethod = "POST"
              urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
          
              let (data, response) = try await session.data(for: urlRequest)
              try APIRequestError.checkResponse(data: data, response: response)
              
              guard let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
                  
                  throw APIRequestError.internalServerError
              }
              
              logger.info("login json \(json)")
              
              if json["requireAddPasskey"] is Bool {
                  throw APIRequestError.accountNoPasskey
              }
               
              let result = try JSONDecoder().decode(LoginChallenge.self, from: data)
              return result
 
             
          }
            catch let error as APIRequestError {
                print("login error \(error.message)")
                throw error
            }
            catch {
                print("login error \(error.localizedDescription)")
                throw error
            }
    }
    
    
    func loginComplete(handle:String, assertion:Assertion) async throws -> AppUser? {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/loginComplete"
        do {
            
            
            let assertRsponse = "{\"authenticatorData\": \"\(assertion.response.authenticatorData)\", \"clientDataJSON\": \"\(assertion.response.clientDataJSON)\", \"signature\": \"\(assertion.response.signature)\", \"userHandle\": \"\(assertion.response.userHandle)\"}"
            
            let moddedHandle = handle.replacingOccurrences(of: "+", with: "%2B")
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: moddedHandle),
                                                URLQueryItem(name: "id", value: assertion.id),
                                                URLQueryItem(name: "response", value: assertRsponse )
                                                ]
           
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            
            let defaults = UserDefaults.standard
            let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["app-token": appToken]
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
       
             
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
            
            // print("loginComplete jsonString \(data.base64URLEncode().base64Decoded() ?? "" )")
            
            var user = try JSONDecoder().decode(AppUser.self, from: data)
            
            if let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] {
                user.accessToken = json["access-token"] as? String
            }
            
            
            self.appUser = user
            self.accessToken = user.accessToken!
            return user
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    
    func userNameAvailable(userName:String) async throws -> Bool {
       
        do {
            
            guard let url = URL(string: "\(Constants.API_URL_ADDRESS)/api/appuser/userNameAvailable?userName=\(userName)") else {
                throw APIRequestError.invalidData
            }
            
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = ["access-token": accessToken]

            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(from: url)
            try APIRequestError.checkResponse(data: data, response: response)
           
            guard let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
                throw APIRequestError.internalServerError
            }
            
            if let available = json["available"] as? Bool {
                return available
            }
            else {
                return false
            }
            
            
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
    }
    
    
    func setUserName(userName:String) async throws -> Bool {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/setUsername"
        do {
            
           
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [
                                                URLQueryItem(name: "userName", value: userName)
                                                ]
           
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.httpMethod = "POST"
            urlRequest.allHTTPHeaderFields = ["access-token": accessToken]
            
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
       
             
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
           
            
            // print("setUsername jsonString \(data.base64URLEncode().base64Decoded() ?? "" )")
            
            return true
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
    }
    
    
    
    func setUserLocale(locale:String) async throws -> Bool {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/setLocale"
        do {
            
           
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [
                                                URLQueryItem(name: "locale", value: locale)
                                                ]
           
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.httpMethod = "POST"
            urlRequest.allHTTPHeaderFields = ["access-token": accessToken]
            
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
       
             
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
           
            
            // print("locale jsonString \(data.base64URLEncode().base64Decoded() ?? "" )")
            
            return true
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            throw error
        }
    }
    
    
    
    func verify(handle:String) async throws -> LoginChallenge? {
          
          let url = "\(Constants.API_URL_ADDRESS)/api/appuser/verify"
          
          do {
              // your post request data
              let moddedHandle = handle.replacingOccurrences(of: "+", with: "%2B")
              
              var requestBodyComponents = URLComponents()
              requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: moddedHandle)]
            
              let config = URLSessionConfiguration.default
              let session = URLSession(configuration: config)
              let url = URL(string: url)!
              
              
              let defaults = UserDefaults.standard
              let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
              
              
              var urlRequest = URLRequest(url: url)
              urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
              urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
              urlRequest.allHTTPHeaderFields = ["app-token":appToken]
              urlRequest.httpMethod = "POST"
              urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
          
              let (data, response) = try await session.data(for: urlRequest)
              try APIRequestError.checkResponse(data: data, response: response)
              
              
              // print("verify return data \(data.base64URLEncode().base64Decoded()!)")
              
              let result = try JSONDecoder().decode(LoginChallenge.self, from: data)
 
              return result
             
          }
            catch let error as APIRequestError {
                print("verify error \(error.message)")
                throw error
            }
            catch {
                print("verify error \(error.localizedDescription)")
                throw error
            }
    }
    
    
    
    
    func verifyComplete(handle:String, assertion:Assertion) async throws -> Bool {
        
        let url = "\(Constants.API_URL_ADDRESS)/api/appuser/verifyComplete"
        do {
            
            
            let assertRsponse = "{\"authenticatorData\": \"\(assertion.response.authenticatorData)\", \"clientDataJSON\": \"\(assertion.response.clientDataJSON)\", \"signature\": \"\(assertion.response.signature)\", \"userHandle\": \"\(assertion.response.userHandle)\"}"
            
            let moddedHandle = handle.replacingOccurrences(of: "+", with: "%2B")
            var requestBodyComponents = URLComponents()
            requestBodyComponents.queryItems = [URLQueryItem(name: "handle", value: moddedHandle),
                                                URLQueryItem(name: "id", value: assertion.id),
                                                URLQueryItem(name: "response", value: assertRsponse )
                                                ]
           
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: url)!
            
            
            let defaults = UserDefaults.standard
            let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
            
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.allHTTPHeaderFields = ["app-token": appToken]
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)
       
             
            let (data, response) = try await session.data(for: urlRequest)
            try APIRequestError.checkResponse(data: data, response: response)
           
            print("verifyComplete return data \(data.base64URLEncode().base64Decoded()!)")
            
            guard let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
                throw APIRequestError.internalServerError
            }
            
            logger.info("verifyComplete json = \(json)")
            
            if let valid = json["valid"] as? Bool {
                return valid
            }
            else {
                return false
            }
        }
        catch let error as APIRequestError {
            throw error
        }
        catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    
}


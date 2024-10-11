//
//  LoginView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AuthenticationServices
import os


struct LoginView: View {
    @State private var email = ""
    @StateObject private var pkManager = PasskeysManager.shared
    @EnvironmentObject var appState: AppState
    @State var loadingStatus = ""
    @State var showingAlert = false
    @State var isLoggedIn = false
    @State var isNoPasskey = false
    @State var anonymousLoginEnabled = false
    @State var signupChallenge:SignupChallenge?
    
    let logger = Logger()
    
    enum Field {
        case handle
    }
    
    @FocusState private var focusedField: Field?
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Image("AppKey").frame(width: 300).padding()
            
            Spacer().frame(height: 150)
            
            Group {
                TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .handle)
                .submitLabel(.send)
              
            }
            .padding(.horizontal)
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.focusedField = Field.handle
                }
            }
            .toolbar{
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        EmptyView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            focusedField = nil
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundColor(.blue).padding(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            
            Button(action: {
                 
                 login()
                
            }) {
                Text("Login")
                    .padding(.horizontal)
                Image(systemName: "arrow.right.square")
            }
            .padding()
            .foregroundColor(Color.white)
            .background(Color.green)
            .cornerRadius(8)
            
            
            if anonymousLoginEnabled  {
                Button(action: {
                    loginAnonymous()
                }) {
                    Text("Anonymous Login")
                        .padding(.horizontal)
                    Image(systemName: "arrow.right.square")
                }
                .padding()
                .foregroundColor(Color.white)
                .background(Color.blue)
                .cornerRadius(8)
            }
        
        }
        
        .frame(
              minWidth: 0,
              maxWidth: .infinity,
              minHeight: 0,
              maxHeight: .infinity,
              alignment: .topLeading
        )
        //.background(Color.white)
        
        .onTapGesture {
            if (focusedField != nil) {
                focusedField = nil
            }
        }
        .onSubmit {
            switch focusedField {
            case .handle:
                login()
            default:
                print("login account…")
                
                
                 
            }
        }
        
        .onChange(of: pkManager.attestationResponse) {
            
            if appState.tabSelection != "Login" {
                return
            }
            
            Task{
                 
                do{
                    if let attestation = pkManager.attestation, let challengeData = signupChallenge {
                       
                        loadingStatus = "verify server challenge"
                        
                        let response = try await API.loginAnonymousComplete(handle: challengeData.user.handle, attest: attestation)
                        logger.log("loginAnonymousComplete  response \(response)")
                    
                        appState.loading = false
                        appState.target = .loggedIn
                        
                    }
                }
                catch {
                    logger.log("passkey  error  \(error.localizedDescription)")
                    appState.loading = false
                    
                    loadingStatus = "Invalid Request"
                    showingAlert.toggle()
                    
                }
                
            }
        }
        
        .onChange(of: pkManager.assertionnResponse) {
            
            if appState.tabSelection != "Login" {
                return
            }
            
            Task {
                if let assert = pkManager.assertion, assert.id != "" {
                    loadingStatus = "verify server challenge"
                    
                    do{
                        
                        let user = try await API.loginComplete(handle: email, assertion: assert)
                        logger.log("Login Complete user \(user!.appUserId)")
                        
                        appState.loading = false
                        
                        if let application = APIManager.shared.application, application.userNamesEnabled, user?.userName == nil {
                            appState.target = .loginUserName
                        }
                        else { appState.target = .loggedIn }
                        
                    }
                    catch let error as APIRequestError {
                        logger.log("Login Complete error \(error.message)")
                        appState.loading = false
                        loadingStatus = error.message
                        showingAlert.toggle()
                        
                    }
                    catch {
                        logger.log("Login Complete error \(error.localizedDescription)")
                        appState.loading = false
                        loadingStatus = error.localizedDescription
                        showingAlert.toggle()
                        
                    }
                }
                
            }
        }
        .onChange(of: pkManager.errorResponse) {
            
            appState.loading = false
            loadingStatus = pkManager.errorResponse ?? "Error Key"
            showingAlert.toggle()
        }
        .onChange(of: pkManager.status) {
            if pkManager.status != "success" {
                appState.loading = false
                
                if pkManager.status == "error" {
                    loadingStatus = "Invalid Authorization"
                    showingAlert.toggle()
                }
                
            }
           
            
        }
        .alert(isPresented: $showingAlert) {
            
            Alert(title: Text("AppKey"),
                  message: Text("\(loadingStatus)"),
                  dismissButton: .default(Text("Got it!"))
            )
            
           
        }
        .onChange(of: appState.anonymousLoginEnabled) {
            anonymousLoginEnabled = appState.anonymousLoginEnabled
        }
        .onAppear{
            anonymousLoginEnabled = appState.anonymousLoginEnabled
        }
    }
    
    
    
    
    func login()  {
        Task{
            do{
                
                if email.isEmpty {
                    loadingStatus = "Invalid Email"
                    showingAlert.toggle()
                    return
                }
                
                loadingStatus = "getting server challenge"
                appState.loading.toggle()
 
                
                if let response = try await API.login(handle: email){
                    
                 
                    
                    if let challengeData = response.challenge.decodeBase64Url {
                        
                        let allowedCredentials = response.allowCredentials.map{$0.id}
                        pkManager.signInWith(anchor: ASPresentationAnchor(), challenge: challengeData, allowedCredentials: allowedCredentials, relyingParty: Constants.RELYING_PARTY_ID, preferImmediatelyAvailableCredentials: false)
                    }
                    else {
                        appState.loading = false
                        loadingStatus = "Invalid Challenge Data"
                        showingAlert.toggle()
                    }
                    
                }
                else {
                    appState.loading = false
                }
                
            }
            catch let error as APIRequestError {
                appState.loading = false
                
                if(error == .accountNoPasskey){
                    appState.loading = false
                    loadingStatus = "Your account does not have passkey. Please signup again."
                    showingAlert.toggle()
                }
                else {
                    loadingStatus = error.message
                    showingAlert.toggle()
                }
                
                logger.error("login error \(error.localizedDescription)")
            }
            catch  {
                appState.loading = false
                loadingStatus = error.localizedDescription
                showingAlert.toggle()
                logger.error("login error \(error.localizedDescription)")
            }
        }
    }
    
    func loginAnonymous()  {
        Task{
            do{
                
                loadingStatus = "getting server challenge"
                appState.loading.toggle()
 
                let uuidString = UUID().uuidString
                if let response = try await API.loginAnonymous(uuidString: uuidString){
                    
                    signupChallenge = response
                    let userId = response.user.id
                    let keyUserName = response.user.name
                    
                    if let challengeData = response.challenge.decodeBase64Url, let userIdData =  userId.data(using: .utf8) {
                        pkManager.signUpWith(userName: keyUserName, userId: userIdData, challenge: challengeData, relyingParty:Constants.RELYING_PARTY_ID, anchor: ASPresentationAnchor())
                    }
                    else {
                        appState.loading = false
                        loadingStatus = "Invalid Challenge Data"
                        showingAlert.toggle()
                    }
                    
                }
                else {
                    appState.loading = false
                }
                
            }
            catch let error as APIRequestError {
                appState.loading = false
                loadingStatus = error.message
                showingAlert.toggle()
                logger.error("login error \(error.localizedDescription)")
            }
            catch  {
                appState.loading = false
                loadingStatus = error.localizedDescription
                showingAlert.toggle()
                logger.error("login error \(error.localizedDescription)")
            }
        }
    }
    
 
}

#Preview {
    LoginView()
}

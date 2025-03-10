//
//  LoginView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AuthenticationServices
import AppKeySwift
import AppKeyGoogleAuth
import GoogleSignInSwift


struct LoginView: View {
    @State private var email = ""
    @State private var provider = ""
    @State private var token = ""
    @StateObject private var pkManager = AKPasskeysManager.shared
    @StateObject private var apiManager = AppKeyAPIManager.shared
    @StateObject var appKeyGoogleAuth = AppKeyGoogleAuth.shared
    
    @EnvironmentObject var appState: AppState
    @State var loadingStatus = ""
    @State var showingAlert = false
    @State var isLoggedIn = false
    @State var isNoPasskey = false
    @State var anonymousLoginEnabled = false
    @State var signupChallenge:AKSignupChallenge?
    @State private var socialLogin: Bool = true
    @State private var isGoogleLogin: Bool = true
    @State private var isAppleLogin: Bool = true
    @State private var idToken = ""
    @State private var requireAddPasskey:Bool = false
    @State private var message: AlertMessage? = nil
 
    
    enum Field {
        case handle
    }
    
    @FocusState private var focusedField: Field?
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                
                Link(destination: URL(string: "https://cosync.io")!) {
                    Image("Cosync").resizable().frame(width: 80.0, height: 80.0).padding()
                }
                
                Spacer()
                
                Link(destination: URL(string: "https://appkey.info")!) {
                    Image("AppKey").resizable().frame(width: 80.0, height: 80.0).padding()
                }
                
                 
            }
            .padding()
            
            Text("Welcome to the AppKey demo! Log in securely using your passkey or sign up with your email to create one in seconds. See for yourself how fast and seamless passkey creation can be with AppKey—no passwords, no hassle, just security made simple.").padding(.horizontal)
            
            
            if requireAddPasskey {
                VStack{
                    
                    Text("Your account has requested a reset passkey token. Please check your email for a reset token.").padding(.horizontal).foregroundStyle(.blue)
                    
                    
                    Group {
                        TextField("Token", text: $token, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(5...10)
                            .submitLabel(.send)
                        
                    }
                    .padding(.horizontal)
                    
                    VStack{
                        
                        Button(action: {
                            
                            addPasskeyHandler()
                            
                        }) {
                            Text("Submit")
                                .padding(.horizontal)
                            Image(systemName: "arrow.right.square")
                        }
                        .font(.system(.title3, design: .rounded))
                        .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .clipShape(Capsule())
                        .frame(minWidth: 250)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                
            }
            else {
                
                
                Group {
                    TextField("Handle", text: $email)
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
                
                VStack{
                    
                    Button(action: {
                        
                        login()
                        
                    }) {
                        Text("Login")
                            .padding(.horizontal)
                        Image(systemName: "arrow.right.square")
                    }
                    .font(.system(.title3, design: .rounded))
                    .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(Capsule())
                    .frame(minWidth: 250)
                    
                    if anonymousLoginEnabled  {
                        Button(action: {
                            loginAnonymous()
                        }) {
                            Text("Anonymous Login")
                                .padding(.horizontal)
                            Image(systemName: "arrow.right.square")
                        }
                        .font(.system(.title3, design: .rounded))
                        .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .clipShape(Capsule())
                    }
                    
                    if socialLogin {
                        VStack (spacing: 10){
                            Text("Or").font(.caption)
                                .foregroundColor(.blue)
                            
                            if isGoogleLogin == true {
                                GoogleSignInButton( scheme: GoogleSignInButtonColorScheme.light,
                                                    style: GoogleSignInButtonStyle.wide,
                                                    action: handleGoogleSignInButton)
                                .frame(minWidth: 150, maxWidth: 200, minHeight:50 , maxHeight: 70)
                                
                            }
                            
                            if isAppleLogin == true {
                                SignInWithAppleButton(.signIn,            //1 .signin, or .continue or .signUp for button label
                                                      onRequest: { (request) in             //2 //Set up request
                                    request.requestedScopes = [.fullName, .email]
                                },
                                                      onCompletion: { result in
                                    switch result {
                                    case .success(let authResults):
                                        handleAppleSignInButton(authorization:authResults)
                                    case .failure(let error):
                                        print("Authorisation failed: \(error.localizedDescription)")
                                        self.showLoginError(message: error.localizedDescription)
                                    }
                                })
                                .signInWithAppleButtonStyle(.whiteOutline) // .black, .white and .whiteOutline
                                .frame(minWidth: 150, maxWidth: 200, minHeight:50, maxHeight:50)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                .fixedSize(horizontal: true, vertical: false)
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
                    if let attestation = pkManager.attestation {
                       
                        loadingStatus = "verify server challenge"
                        
                        if requireAddPasskey {
                          
                            let _ = try await AppKeyAPI.addPasskeyComplete(attest: attestation)
                                
                            loadingStatus = "Success Adding Passkey, Please login again"
                            showingAlert.toggle()
                            requireAddPasskey.toggle()
                        }
                        else if let challengeData = signupChallenge {
                            let response = try await AppKeyAPI.loginAnonymousComplete(handle: challengeData.user.handle, attest: attestation)
                            print("loginAnonymousComplete  response \(response)")
                            
                            appState.target = .loggedIn
                        }
                        
                        appState.loading = false
                       
                        
                    }
                }
                catch let error as AppKeyError {
                    print("Login error \(error.message)")
                    appState.loading = false
                    loadingStatus = error.message
                    showingAlert.toggle()
                    
                }
                catch {
                    print("Login error \(error.localizedDescription)")
                    appState.loading = false
                    loadingStatus = error.localizedDescription
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
                        
                        let user = try await apiManager.loginComplete(handle: email, assertion: assert)
                        print("Login Complete user \(user!.appUserId)")
                        
                        appState.loading = false
                        
                        if let application = apiManager.application, application.userNamesEnabled, user?.userName == nil {
                            appState.target = .loginUserName
                        }
                        else { appState.target = .loggedIn }
                        
                    }
                    catch let error as AppKeyError {
                        print("Login Complete error \(error.message)")
                        appState.loading = false
                        loadingStatus = error.message
                        showingAlert.toggle()
                        
                    }
                    catch {
                        print("Login Complete error \(error.localizedDescription)")
                        appState.loading = false
                        loadingStatus = error.localizedDescription
                        showingAlert.toggle()
                        
                    }
                }
                
            }
        }
        .onChange(of: pkManager.errorResponse) {
            if appState.tabSelection != "Login" { return }
            print("pkManager.errorResponse \(pkManager.errorResponse ?? "")")
            appState.loading = false
            loadingStatus = pkManager.errorResponse ?? "Invalid Authorization Key"
            showingAlert.toggle()
        }
        .onChange(of: appKeyGoogleAuth.idToken) { _,token in
            if token == "" {return}
            
            print("googleAuth User: \(appKeyGoogleAuth.givenName) \(appKeyGoogleAuth.familyName)")
            print("googleAuth idToken: \(token)")
           
            self.googleLogin(token: token)
            
        }
        .onChange(of: appKeyGoogleAuth.errorMessage) { _, message in
            if message == "" {return}
            print("cosyncGoogleAuth message: \(message)")
            self.showLoginError(message: message)
            
        }
        .alert(isPresented: $showingAlert) {
            
            Alert(title: Text("AppKey"),
                  message: Text("\(loadingStatus)"),
                  dismissButton: .default(Text("Got it!"))
            )
            
           
        }
        .onAppear{
            
            Task{
                do{
                    
                   
                    self.appState.loading = true
                    if let application = try await AppKeyAPI.getApp() {
                        
                        print(" application ", application)
                        
                        anonymousLoginEnabled = application.anonymousLoginEnabled
                        isAppleLogin = application.appleLoginEnabled
                        isGoogleLogin = application.googleLoginEnabled
                        
                        if application.appleLoginEnabled == true || application.googleLoginEnabled == true {
                            socialLogin = true
                        }
                        else {
                            socialLogin = false
                        }
                        
                        self.appState.application = application
                        self.appState.anonymousLoginEnabled = application.anonymousLoginEnabled
                    }
                    self.appState.loading = false
                }
                catch {
                    print(error.localizedDescription)
                    self.appState.error = "Invalid App Token"
                    self.appState.loading = false
                }
            }
              
            
        }
    }
    
    
    func addPasskeyHandler(){
        
        Task{
            do{
                
                if self.appState.loading { return }
                
                if token.isEmpty {
                    loadingStatus = "Invalid Token"
                    showingAlert.toggle()
                    return
                }
                
                AppKeyAPI.accessToken = token
                
                loadingStatus = "getting server challenge"
                appState.loading.toggle()
                
                
                let response = try await apiManager.addPasskey()
                let userId = response.user.id
                let keyUserName = response.user.name
                
                if let challengeData = response.challenge.decodeBase64Url, let userIdData =  userId.data(using: .utf8) {
                    pkManager.signUpWith(userName: keyUserName, userId: userIdData, challenge: challengeData, relyingParty:Constants.RELYING_PARTY_ID, anchor: ASPresentationAnchor())
                }
                
            }
            catch let error as AppKeyError {
                appState.loading = false
                loadingStatus = error.message
                showingAlert.toggle()
                
                print("addPasskeyHandler error \(error)")
            }
            catch  {
                appState.loading = false
                loadingStatus = error.localizedDescription
                showingAlert.toggle()
                print("addPasskeyHandler error \(error.localizedDescription)")
            }
        }
    }
    
    func handleGoogleSignInButton() {
        if self.appState.loading { return }
        self.appState.loading = true
        appKeyGoogleAuth.signIn()
    }
    
    
   
   func googleLogin(token:String){
       if self.appState.loading { return }
       Task { @MainActor in
           do{
               self.provider = "google"
               let user = try await apiManager.socialLogin(token, provider: provider)
               
               print(" google social log user \(user)")
               
               self.appState.target = .loggedIn
               
               self.appState.loading = false
               
               
           }
           catch let error as AppKeyError {
               if error == .accountDoesNotExist {
                   self.signupSocialAccount(token: token, email: appKeyGoogleAuth.email, displayName: "\(appKeyGoogleAuth.givenName) \(appKeyGoogleAuth.familyName) ")
               }
               else {
                   
                   self.showLoginError(message: error.message)
               }
           }
           
       }
   }
    
    func handleAppleSignInButton(authorization: ASAuthorization) {
        if self.appState.loading { return }
        //Handle authorization
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
        let identityToken = appleIDCredential.identityToken,
        let idToken = String(data: identityToken, encoding: .utf8)
        else {
            print("error");
            self.showLoginError(message: "Apple Login Fails")
            return
        }
       
        self.appState.loading = true
        
        print("Apple token \(idToken)")
        
        self.idToken = idToken
        self.email = appleIDCredential.email ?? ""
        self.provider = "apple"
  
      
        Task { @MainActor in
            do {
                let user = try await apiManager.socialLogin(self.idToken, provider: provider)
                print(" apple social log user \(user)")
                
                self.appState.target = .loggedIn
                
                self.appState.loading = false
                
            } catch let error as AppKeyError {
                self.appState.loading = false
                print("social login error: \(error.localizedDescription)")
                if error == .accountDoesNotExist {
                    print("social accountDoesNotExist fullName:")
                    print("\(String(describing: appleIDCredential.fullName))")
                    
                    if let name = appleIDCredential.fullName,
                        let givenName = name.givenName,
                        let familyName =  name.familyName {
                        // new account
                        signupSocialAccount(token: self.idToken, email: self.email, displayName: "\(givenName) \(familyName)")
                        
                    }
                    else{
                        let errorMessage = "App cannot access to your iCloud profile name. Please remove this AppKey Login in 'Sign with Apple' from your iCloud setting and try again."
                        self.showLoginError(message: errorMessage)
                    }
                }
                else {
                    let message = error.message
                    self.showLoginError(message: message)
                }
            } catch {
                self.showLoginInvalidParameters()
                self.appState.loading = false
            }
            
        }
    
      
    }
     
    
    func showLoginError(message: String){
        self.appState.loading = false
        self.loadingStatus = message
        showingAlert.toggle()
    }

    func showLoginInvalidParameters(){
        self.loadingStatus = "You have entered an invalid handle."
        showingAlert.toggle()
        
       
    }
    
    func login()  {
        Task{
            do{
                if self.appState.loading { return }
                
                if email.isEmpty {
                    loadingStatus = "Invalid Email"
                    showingAlert.toggle()
                    return
                }
                
                loadingStatus = "getting server challenge"
                appState.loading.toggle()
 
                
                if let response = try await AppKeyAPI.login(handle: email){
                    
                   
                    if let resetPasskey = response.requireAddPasskey {
                        requireAddPasskey = resetPasskey
                       
                    }
                    else if let challengeData = response.challenge.decodeBase64Url {
                        
                        pkManager.signInWith(anchor: ASPresentationAnchor(), challenge: challengeData, allowedCredentials: [], relyingParty: Constants.RELYING_PARTY_ID, preferImmediatelyAvailableCredentials: false)
                    }
                    else {
                       
                        loadingStatus = "Invalid Challenge Data"
                        showingAlert.toggle()
                    }
                    
                }
                 
                appState.loading = false
                
                
            }
            catch let error as AppKeyError {
                appState.loading = false
               
                if(error == .passkeyNotExist){
                    appState.loading = false
                    loadingStatus = "Your account does not have passkey. Please signup again."
                    showingAlert.toggle()
                }
                else {
                    loadingStatus = error.message
                    showingAlert.toggle()
                }
                
                print("login error \(error)")
            }
            catch  {
                appState.loading = false
                loadingStatus = error.localizedDescription
                showingAlert.toggle()
                print("login error \(error.localizedDescription)")
            }
        }
    }
    
    func loginAnonymous()  {
        Task{
            do{
                if self.appState.loading { return }
                
                loadingStatus = "getting server challenge"
                appState.loading.toggle()
 
                let uuidString = UUID().uuidString
                if let response = try await apiManager.loginAnonymous(uuidString: uuidString){
                    
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
            catch let error as AppKeyError {
                appState.loading = false
                loadingStatus = error.message
                showingAlert.toggle()
                print("login error \(error.localizedDescription)")
            }
            catch  {
                appState.loading = false
                loadingStatus = error.localizedDescription
                showingAlert.toggle()
                print("login error \(error.localizedDescription)")
            }
        }
    }
    
    
    
   
    func signupSocialAccount(token:String, email:String, displayName:String)  {
        
        Task {
            do {
                
                self.appState.loading = true
                
                let _ = try await apiManager.socialSignup(token, email:email, provider: self.provider, displayName: displayName)
                    
                self.appState.target = .loggedIn
                
                self.appState.loading = false
                
            } catch let error as AppKeyError {
                self.appState.loading = false
                let message = error.message
                print("signupSocialAccount AppKeyError  \(message)")
                self.showLoginError(message: message)
                
            } catch {
                self.appState.loading = false
                let message = error.localizedDescription as String

                print("signupSocialAccount error localizedDescription \(message)")
                self.showLoginError(message: message)
           
            }
            
        }
        
    }
     
 
}

#Preview {
    LoginView()
}


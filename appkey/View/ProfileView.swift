//
//  ProfileView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
 
import AuthenticationServices
import AppKeySwift
import AppKeyGoogleAuth
import GoogleSignInSwift


struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    @StateObject var appKeyGoogleAuth = AppKeyGoogleAuth.shared
    @State private var locale:String = "EN"
    @State private var isDeleteUser:Bool = false
    @State private var firstName:String = ""
    @State private var lastName:String = ""
    
    @State private var showVerifyAccount:Bool = false
   
    @StateObject private var pkManager = AKPasskeysManager.shared
    @State var errorMessage = ""
    @State var showingAlert = false
    
    enum AlertType {
        case verify
        case deleteAccount
        case error
        case none
    }
    @State var alertType: AlertType = .none
    
    var body: some View {
        VStack{
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
            
            if let appUser = apiManager.appUser {
                
                Text("Welcome to the AppKey demo! Sign up with your email to create your passkey and log in effortlessly. Discover how simple and secure passwordless login can be—no passwords, just your passkey.").padding(.horizontal)
                
                
                Text("Welcome: \(firstName) \(lastName)") .font(.headline)
                
                Text("Handle: \(appUser.handle)") .font(.headline)
                
                if let userName = appUser.userName {
                    Text("User Name: \(userName)") .font(.body)
                }
                
                Divider()
                
                Group {
                    
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true) 
                }
                .padding(.horizontal)
                
                
                
            }
            
            if let app = apiManager.application, app.locales.count > 1 {
                
                HStack{
                    Text("Set Locale")
                    
                    Picker("Set Locale", selection: $locale.onTextChange({ value in
                        print("set locale \(value)")
                        Task{
                            try await apiManager.setUserLocale(locale: value)
                        }
                    }), content: {
                        ForEach(app.locales, id: \.self) { locale in
                            
                            Text("\(locale)").font(.caption).tag("\(locale)")
                        }
                        
                    }).pickerStyle(.menu)
                    
                    
                }
            }
            
            VStack{
                Button(action: {
                    Task{
                        await updateProfile()
                    }
                }) {
                    Text("Update").padding(.horizontal)
                    Image(systemName: "paperplane.circle.fill")
                }
                .font(.system(.title3, design: .rounded))
                .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .background(.blue)
                .clipShape(Capsule())
                
                Spacer().frame(height: 50)
                
                Button(action: {
                    alertType = .deleteAccount
                    isDeleteUser = true
                    showingAlert.toggle()
                }) {
                    Text("Delete Account")
                        .padding(.horizontal)
                    Image(systemName: "trash.square.fill")
                }
                .font(.system(.title3, design: .rounded))
                .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .background(.red)
                .clipShape(Capsule())
                
                Spacer().frame(height: 50)
                
                Button(action: {
                    apiManager.logout()
                    appState.target = .loggedOut
                }) {
                    Text("Logout")
                        .padding(.horizontal)
                    Image(systemName: "arrow.right.square")
                }
                .font(.system(.title3, design: .rounded))
                .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .background(.red)
                .clipShape(Capsule())
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .onAppear{
            
            if let appUser = apiManager.appUser {
                
                self.firstName = appUser.firstName
                self.lastName = appUser.lastName
                
                if let locale = appUser.locale {
                    self.locale = locale
                }
            }
             
           
        }
        .alert(isPresented: $showingAlert) {
            if alertType == .verify {
                return Alert(
                    title: Text("Verify AppKey Account"),
                    message: Text("Please verify your account to manage passkey"),
                    primaryButton: .default(
                        Text("Cancel"),
                        action:{
                            isDeleteUser = false
                        }
                    ),
                    secondaryButton: .destructive(
                        Text("Verify"),
                        action: {
                            verifyAccount()
                        }
                    )
                )
            }
            else if alertType == .error {
                return Alert(title: Text("AppKey Response"),
                    message: Text("\(errorMessage)"),
                    dismissButton: .cancel(Text("Got it!"), action: {})
                )
            }
            else if alertType == .deleteAccount {
                return Alert(
                    title: Text("AppKey Delete Account"),
                    message: Text("Are you sure to delete your account?"),
                    primaryButton: .default(
                        Text("Cancel"),
                        action:{
                            isDeleteUser = false
                        }
                    ),
                    secondaryButton: .destructive(
                        Text("Delete"),
                        action: {
                            verifyAccount()
                        }
                    )
                )
            }
            else {
                return Alert(title: Text("AppKey Response"),
                    message: Text("\(errorMessage)"),
                    dismissButton: .cancel(Text("Got it!"), action: {})
                )
            }
        }
        .onChange(of: pkManager.assertionnResponse) {
            
            if appState.tabSelection != "Profile" { return }
                
            Task {
                if let assert = pkManager.assertion, assert.id != "" {
                     
                    do{
                        
                        _ = try await apiManager.verifyComplete(handle: apiManager.appUser!.handle, assertion: assert)
                       
                        
                        if isDeleteUser {
                            let _ = try await apiManager.deleteAccount()
                            
                            apiManager.logout()
                            appState.target = .loggedOut
                        }
                       
                        appState.loading = false
                        
                    }
                    catch let error as AppKeyError {
                        alertError(error.message)
                    }
                    catch {
                        alertError(error.localizedDescription)
                       
                    }
                }
                
            }
        }
        
        .onChange(of: pkManager.errorResponse) {
            if appState.tabSelection != "Profile" { return }
            
            alertError(pkManager.errorResponse ?? "Error Key")
        }
        .onChange(of: pkManager.status) {
            if appState.tabSelection != "Profile" { return }
            
            if pkManager.status != "success" {
                appState.loading = false
                
                if pkManager.status == "error" {
                    alertError("Invalid Authorization")
                }
                
            }
        }
        .onChange(of: appKeyGoogleAuth.idToken) { _,token in
            if token == "" {return}
            
            print("googleAuth User: \(appKeyGoogleAuth.givenName) \(appKeyGoogleAuth.familyName)")
            print("googleAuth idToken: \(token)")
           
            Task{
                do {
                    let verifyComplete = try await AppKeyAPI.verifySocialAccount(token, provider: "google")
                    print("verifyComplete \(verifyComplete)")
                    
                    let _ = try await apiManager.deleteAccount()
                    
                    appState.loading = false
                    
                    apiManager.logout()
                    appState.target = .loggedOut
                }
                catch let error as AppKeyError {
                    alertError(error.message)
                }
                catch {
                    alertError(error.localizedDescription)
                }
            }
            
        }
        .onChange(of: appKeyGoogleAuth.errorMessage) { _, message in
            if message == "" {return}
            alertError(message)
            print("cosyncGoogleAuth message: \(message)")
        }
        .onChange(of : pkManager.verifcationResponse) {
            if appState.tabSelection != "Profile" { return }
            Task {
                if let appleIDCredential = pkManager.signInWithAppleCredential,  let identityToken = appleIDCredential.identityToken {
                    let idToken = String(data: identityToken, encoding: .utf8)!
                    print("apple login: \(String(describing: idToken))")
                    do{
                        
                        let verifyComplete = try await AppKeyAPI.verifySocialAccount(idToken, provider: "apple")
                        
                        if isDeleteUser {
                            let _ = try await apiManager.deleteAccount()
                            
                            appState.loading = false
                            
                            apiManager.logout()
                            appState.target = .loggedOut
                        }
                        
                    }
                    catch let error as AppKeyError {
                        alertError(error.message)
                        
                    }
                    catch {
                        alertError(error.localizedDescription)
                        
                    }
                }
                
            }
        }
           
    }
        
 
    func updateProfile() async {
        do{
            appState.loading.toggle()
            let _ = try await apiManager.updateProfile(firstName: firstName, lastName: lastName)
        }
        catch let error as AppKeyError {
            alertError(error.message)
        }
        catch  {
            alertError(error.localizedDescription)
        }
        appState.loading = false
    }
  
    
    func verifyAccount()  {
        
        if apiManager.appUser!.loginProvider == "apple" {
            pkManager.signInWithAppleButton(anchor: ASPresentationAnchor())
        }
        else  if apiManager.appUser!.loginProvider == "google" {
            appKeyGoogleAuth.signIn()
        }
        else {
            verify()
        }
    }
     
     
    
    func verify()  {
        Task{
            do{
                 
            
                appState.loading.toggle()
 
                
                if let response = try await AppKeyAPI.verify(handle: apiManager.appUser!.handle){
                    if let challengeData = response.challenge.decodeBase64Url {
                        
                       
                        pkManager.signInWith(anchor: ASPresentationAnchor(), challenge: challengeData, allowedCredentials: [], relyingParty: Constants.RELYING_PARTY_ID, preferImmediatelyAvailableCredentials: false)
                    }
                    else {
                        alertError("Invalid Challenge Data")
                    }
                    
                }
                else {
                    appState.loading = false
                }
                
            }
            catch let error as AppKeyError {
                alertError(error.message)
            }
            catch  {
                alertError(error.localizedDescription)
            }
        }
    }
    
    func alertError(_ message:String) {
        alertType = .error
        appState.loading = false
        errorMessage = message
        showingAlert.toggle()
    }
    
     
    
     
}

#Preview {
    ProfileView()
}

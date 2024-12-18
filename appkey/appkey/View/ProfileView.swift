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
    @StateObject private var pkManager = AKPasskeysManager.shared
    @State var loadingStatus = ""
    @State var showingAlert = false
  
    
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
                
                
                Text("Welcome: \(appUser.displayName)") .font(.headline)
                
                Text("Handle: \(appUser.handle)") .font(.headline)
               
                
                if let userName = appUser.userName {
                    Text("User Name: \(userName)") .font(.body)
                }
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
            
            Spacer().frame(height: 50)
            
            Button(action: {
                isDeleteUser.toggle()
            }) {
                Text("Delete Account")
                    .padding(.horizontal)
                Image(systemName: "trash.square.fill")
            }
            .padding()
            .foregroundColor(Color.white)
            .background(Color.red)
            .cornerRadius(8)
            
            
            Spacer().frame(height: 50)
            
            Button(action: {
                apiManager.logout()
                appState.target = .loggedOut
            }) {
                Text("Logout")
                    .padding(.horizontal)
                Image(systemName: "arrow.right.square")
            }
            .padding()
            .foregroundColor(Color.white)
            .background(Color.green)
            .cornerRadius(8)
        }
        .onAppear{
            
            if let appUser = apiManager.appUser, let locale = appUser.locale {
                self.locale = locale
            }
            else {
                self.locale = "EN"
            }
             
        }
        .alert(isPresented: $showingAlert) {
            
            Alert(title: Text("AppKey"),
                  message: Text("\(loadingStatus)"),
                  dismissButton: .default(Text("Got it!"))
            )
        }
        .alert(isPresented: $isDeleteUser) {
            Alert(
                title: Text("AppKey Delete Account"),
                message: Text("Are you sure to delete your account?"),
                primaryButton: .default(
                    Text("Cancel")
                    
                ),
                secondaryButton: .destructive(
                    Text("Delete"),
                    action: {
                        verifyAccount()
                    }
                )
            )
           
        }
        .onChange(of: pkManager.assertionnResponse) {
            Task {
                if let assert = pkManager.assertion, assert.id != "" {
                    loadingStatus = "verify server challenge"
                    
                    do{
                        
                        let verifyComplete = try await AppKeyAPI.verifyComplete(handle: apiManager.appUser!.handle, assertion: assert)
                        print("verifyComplete \(verifyComplete)")
                        
                        let _ = try await apiManager.deleteAccount()
                        
                        appState.loading = false
                        
                        apiManager.logout()
                        appState.target = .loggedOut
                       
                        
                    }
                    catch let error as AppKeyError {
                       
                        appState.loading = false
                        loadingStatus = error.message
                        showingAlert.toggle()
                        
                    }
                    catch {
                        
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
                   
                    appState.loading = false
                    loadingStatus = error.message
                    showingAlert.toggle()
                    
                }
                catch {
                    
                    appState.loading = false
                    loadingStatus = error.localizedDescription
                    showingAlert.toggle()
                    
                }
            }
            
        }
        .onChange(of: appKeyGoogleAuth.errorMessage) { _, message in
            if message == "" {return}
            print("cosyncGoogleAuth message: \(message)")
            loadingStatus = message
            showingAlert.toggle()
            
        }
        .onChange(of : pkManager.verifcationResponse) {
            
            Task {
                if let appleIDCredential = pkManager.signInWithAppleCredential,  let identityToken = appleIDCredential.identityToken {
                    let idToken = String(data: identityToken, encoding: .utf8)!
                    print("apple login: \(String(describing: idToken))")
                    do{
                        
                        let verifyComplete = try await AppKeyAPI.verifySocialAccount(idToken, provider: "apple")
                        print("verifyComplete \(verifyComplete)")
                        
                        let _ = try await apiManager.deleteAccount()
                        
                        appState.loading = false
                        
                        apiManager.logout()
                        appState.target = .loggedOut
                       
                        
                    }
                    catch let error as AppKeyError {
                       
                        appState.loading = false
                        loadingStatus = error.message
                        showingAlert.toggle()
                        
                    }
                    catch {
                        
                        appState.loading = false
                        loadingStatus = error.localizedDescription
                        showingAlert.toggle()
                        
                    }
                }
                
            }
            
           
        }
        
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
                
            }
            catch  {
                appState.loading = false
                loadingStatus = error.localizedDescription
                showingAlert.toggle()
                
            }
        }
    }
    
     
}

#Preview {
    ProfileView()
}

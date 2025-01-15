//
//  PasskeyView.swift
//  appkey
//
//  Created by Tola Voeung on 7/1/25.
//

import SwiftUI
import AuthenticationServices
import AppKeySwift
import AppKeyGoogleAuth

struct PasskeyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    @State var authenticators:[AKPasskey] = []
    @State private var selectedKey:AKPasskey? = nil
    @State private var keyName:String = ""
    @State private var showVerifyAccount:Bool = false
    @State private var showAddingPasskey:Bool = false
    @State private var showDeletingPasskey:Bool = false
    @State private var showEditingPasskey:Bool = false
    @StateObject private var pkManager = AKPasskeysManager.shared
    @State var errorMessage = "Error Message"
    @State var showingError = false
    @State private var showAlert = false
    @State private var isEditingKey:Bool = false
    
    enum AlertType {
        case verify
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
            
            
            if let appUser = apiManager.appUser,
                appUser.loginProvider == "handle", authenticators.count > 0 {
                
                VStack(alignment: .leading) {
                    
                    Text("Passkey Authenticator:").font(.title)
                  
                    
                    Button(action: {
                        showAddingPasskey = true
                         
                        alertType = .verify
                        showAlert.toggle()
                         
                    }) {
                        Text("Add Key")
                            .padding(.horizontal)
                        Image(systemName: "key")
                    }
                    .padding()
                    .foregroundColor(Color.white)
                    .background(Color.green)
                    .cornerRadius(8)
                
                    ForEach(authenticators, id: \.id) { key in
                    
                        HStack {
                            PasskeyRow(key: key)
                            Spacer()
                            
                            Button(action: {
                                self.selectedKey = key
                                self.showEditingPasskey.toggle()
                               
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.blue)
                            }
                            .alert("Update Passkey", isPresented: $showEditingPasskey) {
                                TextField("Enter Key Name", text: $keyName).textInputAutocapitalization(.words)
                                Button("Update", action: {
                                    self.isEditingKey = true
                                    
                                    self.alertType = .verify
                                    self.showAlert.toggle()
                                })
                                
                                Button("Cancel", role: .cancel) { showEditingPasskey = false }
                            }
                            .padding()
                            
                            if authenticators.count > 1 {
                                
                                Button(action: {
                                    self.selectedKey = key
                                    self.showDeletingPasskey.toggle()
                                    
                                    self.alertType = .verify
                                    self.showAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.red)
                                }
                                .padding()
                            }
                        }
                    }
                }.padding()
               
            }
            else {
                Text("Your account does not have Passkey Authenticator.").font(.title)
            }
        }
        .onAppear{ 
            if let keys = apiManager.appUser?.authenticators {
                authenticators = keys
            }
             
        }
        .alert(isPresented: $showAlert) {
            if alertType == .verify {
                return Alert(
                    title: Text("Verify AppKey Account"),
                    message: Text("Please verify your account to manage passkey"),
                    primaryButton: .default(
                        Text("Cancel"),
                        action:{
                            showAddingPasskey = false
                            showDeletingPasskey = false
                            showEditingPasskey = false
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
            else {
                return Alert(title: Text("AppKey Response"),
                    message: Text("\(errorMessage)"),
                    dismissButton: .cancel(Text("Got it!"), action: {})
                )
            }
        }
 

        .onChange(of: pkManager.errorResponse) {
            if appState.tabSelection != "Passkeys" { return }
            appState.loading = false
            let message = pkManager.errorResponse ?? "Error Key"
            showErrorMessage(message)
        }
        .onChange(of: pkManager.status) {
            if appState.tabSelection != "Passkeys" { return }
            
            if pkManager.status != "success" {
                appState.loading = false
                
                if pkManager.status == "error" {
                    
                    showErrorMessage("Invalid Authorization")
                }
                
            }
        }
        .onChange(of: pkManager.assertionnResponse) {
            
            if appState.tabSelection != "Passkeys" { return }
            
            Task {
                if let assert = pkManager.assertion, assert.id != "" {
                     
                    do{
                        
                        _ = try await apiManager.verifyComplete(handle: apiManager.appUser!.handle, assertion: assert)
                        
                        
                        // start add new passkey
                        if showAddingPasskey {
                            showAddingPasskey = false
                            
                            let response = try await apiManager.addPasskey()
                            
                            
                            let userId = response.user.id
                            let keyUserName = response.user.name
                            
                            if let challengeData = response.challenge.decodeBase64Url, let userIdData =  userId.data(using: .utf8) {
                                pkManager.signUpWith(userName: keyUserName, userId: userIdData, challenge: challengeData, relyingParty:Constants.RELYING_PARTY_ID, anchor: ASPresentationAnchor())
                            }
                            
                        }
                        else if selectedKey != nil && showDeletingPasskey {
                            showDeletingPasskey = false
                             
                            let response = try await apiManager.removePasskey(keyId: selectedKey!.id)
                           
                            authenticators = response!.authenticators
                            selectedKey = nil
                        }
                       
                        else if isEditingKey && selectedKey != nil {
                            showEditingPasskey = false
                            await updateKeyName()
                        }
                        
                        appState.loading = false
                        
                    }
                    catch let error as AppKeyError {
                       
                        self.appState.loading = false
                        showErrorMessage(error.message)
                        
                    }
                    catch {
                        print(error.localizedDescription)
                        appState.loading = false
                        showErrorMessage(error.localizedDescription)
                        
                    }
                }
                
            }
        }
        .onChange(of: pkManager.attestationResponse) {
            if appState.tabSelection != "Passkeys" { return }
            
            Task{
               await attestationResponseHandler()
            }
        }
        
    }
    
     
    
    func attestationResponseHandler() async {
        appState.loading = true
        do{
            if let attestation = pkManager.attestation {
                let result = try await AppKeyAPI.addPasskeyComplete(attest: attestation)
                authenticators = result.authenticators;
                
            }
        }
        catch let error as AppKeyError {
            showErrorMessage(error.message)
        }
        catch  {
            print(error)
            showErrorMessage(error.localizedDescription)
        }
        
        appState.loading = false
    }
     
     
    
    func verifyAccount()  {
        Task{
            do{
                appState.loading.toggle()
                
                if let response = try await AppKeyAPI.verify(handle: apiManager.appUser!.handle){
                    if let challengeData = response.challenge.decodeBase64Url {
                        
                       
                        pkManager.signInWith(anchor: ASPresentationAnchor(), challenge: challengeData, allowedCredentials: [], relyingParty: Constants.RELYING_PARTY_ID, preferImmediatelyAvailableCredentials: false)
                    }
                    else {
                        appState.loading = false
                        
                        showErrorMessage("Invalid Challenge Data")
                    }
                    
                }
                else {
                    appState.loading = false
                }
                
            }
            catch let error as AppKeyError {
                appState.loading = false
                showErrorMessage(error.message)
            }
            catch  {
                appState.loading = false
                showErrorMessage(error.localizedDescription)
                
                
            }
        }
    }
    
    func updateKeyName() async {
        do{
            if let response = try await AppKeyAPI.updatePasskey(keyId: selectedKey!.id, keyName: keyName){
                authenticators = response.authenticators;
            }
        }
        catch let error as AppKeyError {
            appState.loading = false
            showErrorMessage(error.message)
            
        }
        catch  {
            appState.loading = false
            showErrorMessage(error.localizedDescription)
          
            
        }
    }
    
    private func showErrorMessage(_ message:String){
        self.errorMessage = message
        self.alertType = .error
        self.showAlert = true
    }
    
}

#Preview {
    PasskeyView()
}

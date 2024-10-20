//
//  SignupView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AuthenticationServices
import os

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    
    @State private var handle = ""
    @State private var displayName = ""
    @State private var code = ""
    @State private var locale = "EN"
    @State private var username = ""
    
    @StateObject private var pkManager = AKPasskeysManager.shared
    @State var loading = false
    @State var loadingStatus = ""
    @State var showingAlert = false
    @State var isLoggedIn = false
    @State var isConfirmingCode = false
    @State  var signupToken:String = ""
    
    enum Field {
        case displayName
        case handle
        case code
         
    }
    @FocusState private var focusedField: Field?

    let logger = Logger()
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Image("AppKey").frame(width: 300).padding()
            
            Spacer().frame(height: 50)
            
        
            Group {
                TextField("Full Name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .displayName)
                    .textContentType(.givenName)
                    .submitLabel(.next)
                
            }
            .padding(.horizontal)
            
            Group {
                TextField("Handle", text: $handle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .handle)
                    .textContentType(.emailAddress)
                    .overlay(RoundedRectangle(cornerRadius: 1).stroke(handle.isValidEmail || handle.isEmpty ? Color.clear : Color.red, lineWidth: 1))
                    .submitLabel(.send)
            }
            .padding(.horizontal)
            
        
            if let app = apiManager.application, app.locales.count > 1 {
                
                HStack{
                    Text("Choose Locale")
                    
                    Picker("Choose Locale", selection: $locale.onTextChange({ value in
                        print("Choose locale \(value)")
                         
                    }), content: {
                        ForEach(app.locales, id: \.self) { locale in
                       
                            Text("\(locale)").font(.caption).tag("\(locale)")
                        }
                        
                    }).pickerStyle(.menu)
                    
                   
                }
            }
            
            if isConfirmingCode {
                
                Text("\(loadingStatus)").font(.headline)
                
                
                Group {
                    TextField("Code", text: $code)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .code)
                        .textContentType(.oneTimeCode)
                        .submitLabel(.send)
                        
                }
                .padding(.horizontal)
                
                
                Button(action: {
                    
                    signupComplete()
                    
                }) {
                    Text("Submit")
                        .padding(.horizontal)
                    Image(systemName: "arrow.right.square")
                }
                .padding()
                .foregroundColor(Color.white)
                .background(Color.green)
                .cornerRadius(8)
                
                
                
                Button(action: {
                    isConfirmingCode = false
                }) {
                    Text("Cancel")
                        .padding(.horizontal)
                    Image(systemName: "arrow.right.square")
                }
                .padding()
                .foregroundColor(Color.white)
                .background(Color.orange)
                .cornerRadius(8)
            }
            else {
                
                Button(action: {
                     signup()
                }) {
                    Text("Signup")
                        .padding(.horizontal)
                    Image(systemName: "arrow.right.square")
                }
                .padding()
                .foregroundColor(Color.white)
                .background(Color.green)
                .cornerRadius(8)
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
        
        .onTapGesture {
            if (focusedField != nil) {
                focusedField = nil
            }
        }
        .onSubmit {
            
            switch focusedField {
            case .displayName:
                focusedField = .handle
            
            default:
                print("Creating account…")
                
                if focusedField == .handle {
                    signup()
                    focusedField = Field.code
                }
                else if focusedField == .code {
                    signupComplete()
                }
                 
            }
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.focusedField = Field.displayName
            }
        }
        .onChange(of: pkManager.attestationResponse) {
            
            if appState.tabSelection != "Signup" {
                return
            }
            
            Task{
               await attestationResponseHandler()
            }
        }
        .onChange(of: pkManager.status) {  _, _ in
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
        
    }
    
    
    func attestationResponseHandler() async {
         
        do{
            if let attestation = pkManager.attestation {
                loadingStatus = "verify server challenge"
                
                let signData = try await AppKeyAPI.signupConfirm(handle: handle, attest: attestation)
                    
                appState.loading = false
                
                if let token = signData.signUpToken, token != ""  {
                    loadingStatus = signData.message
                    isConfirmingCode = true
                    signupToken = token
                }
                else {
                    loadingStatus = "Invalid Request"
                    showingAlert.toggle()
                }
                
                
            }
        }
        catch {
            logger.log("Signup Complete error  \(error.localizedDescription)")
            appState.loading = false
            
            loadingStatus = "Invalid Request"
            showingAlert.toggle()
            
        }
        
         
    }
    
    func signup() {
        Task{
            
            if handle.isEmpty || !handle.isValidEmail{
                loadingStatus = "Please enter a valid email"
                showingAlert.toggle()
                return
            }
            
            loadingStatus = "getting server challenge"
            appState.loading = true
            do {
                if let response = try await AppKeyAPI.signup(handle: handle, displayName:displayName){
                           
                    let userId = response.user.id
                    let keyUserName = response.user.name
                    
                    if let challengeData = response.challenge.decodeBase64Url, let userIdData =  userId.data(using: .utf8) {
                        pkManager.signUpWith(userName: keyUserName, userId: userIdData, challenge: challengeData, relyingParty:Constants.RELYING_PARTY_ID, anchor: ASPresentationAnchor())
                    }
                    else {
                        appState.loading = false
                        loadingStatus = "Invalid Server Challenge"
                        showingAlert.toggle()
                    }
                }
                
                appState.loading = false
            }
            catch let error as AppKeyError {
                
                appState.loading = false
                loadingStatus = error.message
                showingAlert.toggle()
            }
        }
    }
    
    
    func signupComplete() {
        Task{
            loadingStatus = ""
            
            if code.isEmpty{
                loadingStatus = "Invalid Code"
                showingAlert.toggle()
                return
            }
            
            loadingStatus = "verify account"
            appState.loading = true
            do {
                let user = try await AppKeyAPI.signupComplete(signupToken: signupToken, code:code)
                appState.loading = false
                
                if apiManager.application?.userNamesEnabled == true {
                   appState.target = .loginUserName
                }
                else { appState.target = .loggedIn }
                
            }
            catch let error as AppKeyError {
                appState.loading = false
                loadingStatus = error.message
                showingAlert.toggle()
            }
            
            catch {
                appState.loading = false
                loadingStatus = error.localizedDescription as String
                showingAlert.toggle()
            }
        }
    }
        
}

#Preview {
    SignupView()
}

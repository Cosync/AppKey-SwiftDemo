//
//  SignupView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AuthenticationServices
import os
import AppKeySwift

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    
    @State private var handle = ""
    @State private var firstName = ""
    @State private var lastName = ""
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
        case firstName
        case lastName
        case handle
        case code
         
    }
    @FocusState private var focusedField: Field?

    let logger = Logger()
    
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
            
            Text("Welcome to the AppKey demo! Sign up with your email to create your passkey and log in effortlessly. Discover how simple and secure passwordless login can be—no passwords, just your passkey.").padding(.horizontal)
            
            
            
        
            Group {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .firstName)
                    .textContentType(.givenName)
                    .submitLabel(.next)
                
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .lastName)
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
                
            }
            
            VStack{
                if isConfirmingCode {
                    
                    Button(action: {
                        
                        signupComplete()
                        
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
                    
                    
                    
                    
                    Button(action: {
                        isConfirmingCode = false
                    }) {
                        Text("Cancel")
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
                else {
                    
                    Button(action: {
                        signup()
                    }) {
                        Text("Signup")
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
            }
            .fixedSize(horizontal: true, vertical: false)
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
            case .firstName:
                focusedField = .handle
            case .lastName:
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
                self.focusedField = Field.firstName
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
        .onChange(of: pkManager.errorResponse) {
            if appState.tabSelection != "Singup" { return }
            print("pkManager.errorResponse \(pkManager.errorResponse ?? "")")
            appState.loading = false
            loadingStatus = pkManager.errorResponse ?? "Invalid Authorization Key"
            showingAlert.toggle()
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
            
            if let handleType = apiManager.application?.handleType{
                if handle.isEmpty {
                    loadingStatus = "Please enter a valid handle"
                    showingAlert.toggle()
                    
                }
                else if handleType == "email" && !handle.isValidEmail {
                    loadingStatus = "Please enter a valid email"
                    showingAlert.toggle()
                    return
                }
                else if handleType == "phone" && !handle.isValidPhone {
                    loadingStatus = "Please enter a valid phone number"
                    showingAlert.toggle()
                    return
                }
                
            }
            
            if firstName.isEmpty || lastName.isEmpty {
                loadingStatus = "Please enter all required fields"
                showingAlert.toggle()
                return
            }
            
            loadingStatus = "getting server challenge"
            appState.loading = true
            do {
                if let response = try await AppKeyAPI.signup(handle: handle, firstName:firstName, lastName:lastName, locale:locale){
                           
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
                let _ = try await AppKeyAPI.signupComplete(signupToken: signupToken, code:code)
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

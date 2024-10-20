//
//  VerifyView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//


import SwiftUI
import AuthenticationServices
import os
import AppKeySwift


struct VerifyView: View {
    @State private var email = ""
    @StateObject private var pkManager = AKPasskeysManager.shared
    @EnvironmentObject var appState: AppState
    @State var loadingStatus = ""
    @State var showingAlert = false
  
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
                 
                 verify()
                
            }) {
                Text("Verify")
                    .padding(.horizontal)
                Image(systemName: "arrow.right.square")
            }
            .padding()
            .foregroundColor(Color.white)
            .background(Color.green)
            .cornerRadius(8)
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
                verify()
            default:
                print("verify account…")
            }
        }
        .onChange(of: pkManager.assertionnResponse) {
            
            if appState.tabSelection != "Verify" {
                return
            }
            
            Task {
                if let assert = pkManager.assertion, assert.id != "" {
                    loadingStatus = "verify server challenge"
                    
                    do{
                        
                        let result = try await AppKeyAPI.verifyComplete(handle: email, assertion: assert)
                        logger.log("verify Complete result \(result)")
                        
                        loadingStatus = result ? "Successed Verification" : "Failed Verification"
                        showingAlert.toggle()
                        
                        appState.loading = false
                        
                    }
                    catch let error as AppKeyError {
                        logger.log("verify Complete error \(error.message)")
                        appState.loading = false
                        loadingStatus = error.message
                        showingAlert.toggle()
                        
                    }
                    catch {
                        logger.log("verify Complete error \(error.localizedDescription)")
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
         
    }
    
    
    
    
    func verify()  {
        Task{
            do{
                
                if email.isEmpty {
                    loadingStatus = "Invalid Email"
                    showingAlert.toggle()
                    return
                }
                
                loadingStatus = "getting server challenge"
                appState.loading.toggle()
 
                
                if let response = try await AppKeyAPI.verify(handle: email){
                    
                 
                    
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
            catch let error as AppKeyError {
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
    VerifyView()
}

 

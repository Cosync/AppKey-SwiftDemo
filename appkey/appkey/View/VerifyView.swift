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
  
 
    
    enum Field {
        case handle
    }
    
    @FocusState private var focusedField: Field?
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Image("AppKey").frame(width: 300).padding()
            
            Spacer().frame(height: 50)
            
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
            
            Button(action: {
                 
                 verify()
                
            }) {
                Text("Verify")
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
        .fixedSize(horizontal: true, vertical: false)
        
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
                        
                        let _ = try await AppKeyAPI.verifyComplete(handle: email, assertion: assert)
                    
                        
                        loadingStatus = "Successed Verification"
                        showingAlert.toggle()
                        
                        appState.loading = false
                        
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
    VerifyView()
}

 

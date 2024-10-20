//
//  SetUsernameView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI

struct SetUsernameView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    @State private var userName = ""
    @FocusState var focusedUsername: Bool?
    @State var isSettingUserName = false
    @State private var message = ""
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 20){
            Text("Please enter user name").font(.title3)
            
            Group {
                
                TextField("User Name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .focused($focusedUsername, equals: true)
                    .onAppear {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.focusedUsername = true
                      }
                    }
            }
            .padding(.horizontal)
            
            Divider()
            
            if isSettingUserName {
                ProgressView()
            }
             
            
            Button(action: {
                
                Task {
                    if userName.isEmpty {
                        userNameIsInvalid(text:"Please enter a valid user name")
                    } else {
                        isSettingUserName = true
                        do {
                            if try await apiManager.userNameAvailable(userName: userName) {
                                let _ = try await apiManager.setUserName(userName: userName)
                                self.appState.target = .loggedIn
                            }
                            else {
                                userNameIsInvalid(text:"User name is not available")
                            }
                            
                            isSettingUserName = false
                           
                            
                        } catch {
                            isSettingUserName = false
                            self.showErrorLoginUserName(err: error)
                        }
                    }
                }
                 
            }) {
                Text("Submit")
                    .padding(.horizontal)
                Image(systemName: "arrow.right.square")
            }
            .padding()
            .foregroundColor(Color.white)
            .background(Color.green)
            .cornerRadius(8)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert."),
                  message: Text("\(message)"))
        }
    }
    
    func userNameIsInvalid(text:String){
        showAlert.toggle()
        self.message =  text;
    }
    
    func showErrorLoginUserName(err: Error?){
        showAlert.toggle()
        if let error = err as? AppKeyError {
            self.message =  error.message
        }
        else {
            self.message =  "Invalid Data"
        }
    }
}

#Preview {
    SetUsernameView()
}

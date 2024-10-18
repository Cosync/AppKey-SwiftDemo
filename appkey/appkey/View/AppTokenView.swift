//
//  AppTokenView.swift
//  appkey
//
//  Created by Tola Voeung on 18/10/24.
//

import SwiftUI

struct AppTokenView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var token = ""
    enum Field {
        case token
    }
    @FocusState private var focusedField: Field?
    @State var showingAlert = false
    @State var loadingStatus = ""
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image("AppKey").frame(width: 300).padding()
            
            Spacer().frame(height: 30)
            
            Group {
                TextField("App Token", text: $token, prompt: Text("Please your app token"), axis: .vertical)
                            .padding()
                            .background(.blue.opacity(0.2))
                            .cornerRadius(5.0)
                            .focused($focusedField, equals: .token)

              
            }
            .padding(.horizontal)
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.focusedField = Field.token
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
                 
                setAppToken()
                
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
            case .token:
                setAppToken()
            default:
                print("app token default action…")
            }
        }
         
        .alert(isPresented: $showingAlert) {
            
            Alert(title: Text("AppKey"),
                  message: Text("\(loadingStatus)"),
                  dismissButton: .default(Text("Got it!"))
            )
            
           
        }
         
    }
    
    func setAppToken()  {
        Task{
            appState.loading = true
            
           
            
            let defaults = UserDefaults.standard
            defaults.set(token, forKey: "appToken")
            
            do {
                if let app = try await API.getApp() {
                    
                    print("setAppToken  app ", app)
                    
                    self.appState.application = app
                    self.appState.anonymousLoginEnabled = app.anonymousLoginEnabled
                    
                    loadingStatus = "Your application is \(app.name)"
                    showingAlert.toggle()
                }
            }
            catch {
                loadingStatus = "Invalid App Token"
                showingAlert.toggle()
            }
            
            focusedField = nil
            appState.loading = false
        }
        
        
    }
}

#Preview {
    AppTokenView()
}

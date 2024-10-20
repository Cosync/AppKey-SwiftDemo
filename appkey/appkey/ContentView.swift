//
//  ContentView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AuthenticationServices
import AppKeySwift

struct ContentView: View {
   
   @EnvironmentObject var appState: AppState
    
    init() {
        let defaults = UserDefaults.standard
        let appToken = defaults.object(forKey: "appToken") as? String ?? Constants.APP_TOKEN
        
        AppKeyAPIManager.shared.configure(appToken: appToken,
                                          appKeyRestAddress: Constants.API_URL_ADDRESS)

    }
   
   var body: some View {
       ZStack{
            
           if self.appState.target == .loggedOut {
               LoggedOutView()
           } else if self.appState.target == .loggedIn {
               ProfileView()
            
           } else if self.appState.target == .loginUserName {
               SetUsernameView()
           }
           
           if(self.appState.loading){
               ZStack{
                   Color.blue.opacity(0.7)
                       .frame(width: 80, height: 80)
                       .cornerRadius(10)
                   
                   ProgressView()
                       .frame(width: 50, height: 50)
                       .foregroundColor(.blue)
               }
           }
           
       }
   }
   
   
   
}


//
//  LoggedOutView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AuthenticationServices
import AppKeySwift
import AppKeyGoogleAuth

struct LoggedOutView: View {
   
   @EnvironmentObject var appState: AppState
    
   @State var selection: String = "Login"
   
   var body: some View {
       ZStack{
           TabView (selection: $selection){
               
               LoginView().tabItem {
                   Image(systemName: "arrow.right.square")
                   Text("Login")
               }.tag("Login")
               
               VerifyView().tabItem {
                   Image(systemName: "bonjour")
                   Text("Verify")
               }.tag("Verify")
               
               SignupView().tabItem {
                   Image(systemName: "person.badge.plus")
                   Text("Signup")
               }.tag("Signup") 
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
           
           if(self.appState.error != ""){
               VStack{
                   
                   
                   VStack(alignment: .center, spacing: 8) {
                       
                       Text("ERROR").foregroundColor(.red)
                       
                       Text(self.appState.error).foregroundColor(.white)
                           
                           Spacer().frame(height: 20)
                           
                           Button(action: {
                               self.appState.error = ""
                           }) {
                               Text("Close").padding(.horizontal)
                           }
                           .padding()
                           .foregroundColor(Color.white)
                           .background(Color.blue)
                           .cornerRadius(8)
                   }
                   .frame(minWidth: 250, maxHeight: .infinity)
                   .padding()
               }
               .fixedSize(horizontal: false, vertical: true)
               .background(Color.gray)
               .cornerRadius(10)
           }
           
           if(self.appState.success != ""){
               VStack{
                   
                   
                   VStack(alignment: .center, spacing: 8) {
                       
                       Text("SUCCESS").foregroundColor(.blue)
                       
                       Text(self.appState.success).foregroundColor(.white)
                           
                           Spacer().frame(height: 20)
                           
                           Button(action: {
                               self.appState.success = ""
                           }) {
                               Text("Close").padding(.horizontal)
                           }
                           .padding()
                           .foregroundColor(Color.white)
                           .background(Color.blue)
                           .cornerRadius(8)
                   }
                   .frame(minWidth: 250, maxHeight: .infinity)
                   .padding()
               }
               .fixedSize(horizontal: false, vertical: true)
               .background(Color.gray)
               .cornerRadius(10)
           }
           
           
       }
       .onAppear{
           self.appState.tabSelection = selection
           
            
       }
       .onChange(of: selection){
           print("tab selection ", selection)
           appState.tabSelection = selection
       }
   }
   
   
   
}


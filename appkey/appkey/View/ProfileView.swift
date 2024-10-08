//
//  ProfileView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = APIManager.shared
    @State private var locale:String = "EN"
    var body: some View {
        VStack{
            if let appUser = apiManager.appUser {
                
                Text("Welcome: \(appUser.displayName)") .font(.largeTitle)
                
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
    }
}

#Preview {
    ProfileView()
}

//
//  LoggedInView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI
import AppKeySwift

struct LoggedInView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    
    @State var selection: String = "Profile"
    
    var body: some View {
        ZStack{
            TabView (selection: $selection){
                
                ProfileView().tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }.tag("Profile")
                
                PasskeyView().tabItem {
                    Image(systemName: "key.icloud")
                    Text("Passkeys")
                }.tag("Passkeys") 
            }
        }
        .onAppear(){
            self.appState.tabSelection = selection
        }
        .onChange(of: selection){
            print("tab selection ", selection)
            appState.tabSelection = selection
        }
    }
}

#Preview {
    LoggedInView()
}

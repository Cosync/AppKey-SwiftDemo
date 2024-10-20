//
//  LoggedInView.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//

import SwiftUI

struct LoggedInView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var apiManager = AppKeyAPIManager.shared
    
    var body: some View {
        VStack{
            if let appUser = apiManager.appUser {
                Text("Welcome: \(appUser.displayName)")
                    .font(.largeTitle)
                
            }
            
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
    }
}

#Preview {
    LoggedInView()
}

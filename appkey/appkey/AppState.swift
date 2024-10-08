//
//  AppState.swift
//  appkey
//
//  Created by Tola Voeung on 8/10/24.
//
//
 

import Foundation

// View table used for routing. Updated when a new view is added
enum TargetUI: Int {
    case none
    case loggedOut
    case loginComplete
    case loginUserName
    case loggedIn
    case password
   
}



// Global state observable used to trigger routing
class AppState: ObservableObject {
    @Published var target: TargetUI = .loggedOut
    @Published var loading = false
    @Published var error = ""
    @Published var success = ""
    @Published var welcomeText = ""
    @Published var application:Application?
    @Published var anonymousLoginEnabled = false
    @Published var tabSelection = "Login"
}
 

// Alert message container
struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let target: TargetUI
    let state: AppState
}

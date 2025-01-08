//
//  PasskeyRow.swift
//  appkey
//
//  Created by Tola Voeung on 3/1/25.
//

import SwiftUI
import AuthenticationServices
import AppKeySwift
  

struct PasskeyRow: View {
    
    
    var key:AKPasskey
    var body: some View {
        HStack {
            Text(key.name) 
            
        }
        
    }
    
}

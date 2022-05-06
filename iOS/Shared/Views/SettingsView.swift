//
//  SettingsView.swift
//  dscan
//
//  Created by tizian on 05.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"
        
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            Form{
                VStack {
                    TextField(
                        "Server URL",
                        text: $serverurl
                    )
                    .disableAutocorrection(true)
                }
                .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

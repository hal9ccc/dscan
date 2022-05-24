//
//  JSONUI.swift
//  dscan
//
//  Created by Matthias Schulze on 24.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import JSONDrivenUI

struct JSONUI: View {
    let input: String
    
    @EnvironmentObject var app: DScanApp
        
    var body: some View {
        let d = input.data(using: .utf8)
        
        ZStack {
            if input > "" {
                ZStack { // HACK
                    Text("\(app.lastChange.formatted())").font(.caption).opacity(0)
                    JSONDataView(json: d!)
                }
            }
        }
    }
}

struct JSONUI_Previews: PreviewProvider {
    static var previews: some View {
//        StatusLabel()
        Spacer()
    }
}

//
//  File.swift
//  dscan
//
//  Created by Matthias Schulze on 23.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//


import SwiftUI

struct InfoBox: View {
    let info: String
    
    @EnvironmentObject var app: DScanApp
        
    var body: some View {
        let b = app.lastChange == .distantPast ? true : false
        let s = MediaStatus.list.first(where: { $0.id == "info" }) ?? MediaStatus.defo
        
        ZStack {
            if info > "" {
                ZStack { // HACK
                    Text("\(app.lastChange.formatted())").font(.caption).opacity(0)

                    Label("\(b ? "dude" : info)", systemImage: s.icon)
                        .font(.callout)
                        .foregroundColor(s.color)
                        .padding(.horizontal, 2)
                        .frame(maxHeight:75)
                        .if(info == "") { view in view.hidden() }
                }
                
            }
        }
        
    }
}

struct InfoBox_Previews: PreviewProvider {
    static var previews: some View {
//        StatusLabel()
        Spacer()
    }
}

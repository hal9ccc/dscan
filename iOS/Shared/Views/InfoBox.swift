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
    
//    @EnvironmentObject var app: DScanApp
        
    var body: some View {
//        ZStack {
            if info > "" {
//                ZStack { // HACK
//                    Text("\(app.lastChange.formatted())").font(.caption).opacity(0)

                    ChatBubble(direction: .right) {
                        Text("\(info)")
//                        Label("\(info)", systemImage: s.icon)
                            .font(.callout)
                            .padding([.top, .bottom], 8)
                            .padding([.leading, .trailing], 12)
                        //                            .foregroundColor(s.color)
                            .foregroundColor(Color.white)
                            .background(Color.blue)

                    }
//                    .if(info == "") { view in view.hidden() }
                }
//            }
//        }
    }
}

struct InfoBox_Previews: PreviewProvider {
    static var previews: some View {
//        StatusLabel()
        Spacer()
    }
}

//
//  StatusLabel.swift
//  dscan
//
//  Created by Matthias Schulze on 23.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct MediaStatus: Hashable, Identifiable, Equatable {
    let id:           String
    let color:        Color
    let icon:         String

    static let list: [MediaStatus] = [
        MediaStatus ( id: "new",       color: .mint,     icon: "doc"                             ),
        MediaStatus ( id: "scanned",   color: .blue,     icon: "doc.text"                        ),
        MediaStatus ( id: "success",   color: .green,    icon: "checkmark.circle.fill"           ),
        MediaStatus ( id: "warning",   color: .orange,   icon: "exclamationmark.triangle.fill"   ),
        MediaStatus ( id: "info",      color: .yellow,   icon: "info.circle"                     ),
        MediaStatus ( id: "error",     color: .red,      icon: "xmark.octagon.fill"              )
    ]
    
    static let defo = MediaStatus ( id: "unknown", color: .secondary, icon: "checkmark.seal")
    
}


struct StatusLabel: View {
    let media: Media
    @EnvironmentObject  var app:    DScanApp

    var body: some View {
        let s = MediaStatus.list.first(where: { $0.id == media.status }) ?? MediaStatus.defo
        
        ZStack(alignment: .topLeading) { // HACK
            Text("\(app.lastChange.formatted())").font(.caption).opacity(0)

            Label("\(media.status)", systemImage: s.icon)
                .font(.caption)
                .foregroundColor(s.color)
                .padding(.horizontal, 2)
               .if(media.status == "" || media.status == "␀") { view in view.hidden() }
        }
    }
   
}

struct StatusLabel_Previews: PreviewProvider {
    static var previews: some View {
//        StatusLabel()
        Spacer()
    }
}

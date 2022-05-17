//
//  SectionHeader.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct SectionHeader: View {
    var name: String
    var icon: String = ""
    var pill: Int = 0

    var body: some View {
        HStack {
            if icon > "" {
                Label("\(name)", systemImage: icon).labelStyle(.automatic)
            } else {
                Label("\(name)", systemImage: icon).labelStyle(.titleOnly)
            }
            Spacer()
            Text("\(pill)")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .opacity(pill > 0 ? 1 : 0)
                    
        }
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader(name:"Earthquakes", icon:"mappin.and.ellipse", pill:3333)
    }
}

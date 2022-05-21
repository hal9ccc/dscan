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
        return HStack {
            VStack (alignment: .leading) {
                ForEach(name.split(separator: "⸱"), id: \.self) { str in
                    Label(str, systemImage: icon)
                        .if (icon == "") { v in v.labelStyle(.titleOnly)}
                }
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

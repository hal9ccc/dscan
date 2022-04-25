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
    var pill: String

    var body: some View {
        HStack {
            Text("\(name)")
            Spacer()
            Text("\(pill)")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader(name:"Earthquakes", pill:"3333")
    }
}

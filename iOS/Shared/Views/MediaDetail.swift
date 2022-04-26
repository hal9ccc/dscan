//
//  MediaDetail.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//


import Foundation
import SwiftUI
import NukeUI

struct MediaDetail: View {
    var media: Media
    
    var body: some View {
        VStack {
            LazyImage(source: media.img, resizingMode: .center)
                .frame(height: 500)

            Text(media.code)
                .font(.title3)
                .bold()

            Text("\(media.carrier)")
                .foregroundStyle(Color.primary)

            Text("\(media.time.formatted())")
                .foregroundStyle(Color.secondary)
            
            Text(media.description)
        }
        .navigationTitle(title)
    }
    
    var title: String {
        "\(media.carrier) #\(media.code)"
    }
}

struct MediaDetail_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetail(media: .preview)
    }
}

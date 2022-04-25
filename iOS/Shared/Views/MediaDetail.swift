//
//  MediaDetail.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//


import Foundation
import SwiftUI

struct MediaDetail: View {
    var media: Media
    
    var body: some View {
        VStack {
            MediaThumbnail(media: media)

            Text(media.code)
                .font(.title3)
                .bold()

            Text("\(media.carrier)")
                .foregroundStyle(Color.primary)

            Text("\(media.time.formatted())")
                .foregroundStyle(Color.secondary)
            
            Text(media.description)
        }
    }
}

struct MediaDetail_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetail(media: .preview)
    }
}

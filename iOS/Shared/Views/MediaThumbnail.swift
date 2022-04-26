//
//  MediaThumbnail.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import NukeUI

struct MediaThumbnail: View {
    var media: Media
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
//            .fill(.black)
            .frame(width: 100, height: 100)
            .overlay {
                LazyImage(source: media.img)
            }
    }
}

struct MediaThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        MediaThumbnail(media: .preview)
    }
}

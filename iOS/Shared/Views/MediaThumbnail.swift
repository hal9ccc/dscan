//
//  MediaThumbnail.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct MediaThumbnail: View {
    var media: Media
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.black)
            .frame(width: 80, height: 60)
            .overlay {
                AsyncImage(url: URL(string: media.img))
                    .scaledToFill()
                //NetworkImage (url: URL(string: media.img), mode:"fill" )
            }
            .overlay {
                Text("\(media.idx)")
                    .font(.footnote)
                    .bold()
            }
    }
}

struct MediaThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        MediaThumbnail(media: .preview)
    }
}

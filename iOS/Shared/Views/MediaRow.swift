//
//  MediaRow.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct MediaRow: View {
    var media: Media
    
    var body: some View {
        HStack {
            MediaThumbnail(media: media)
            VStack(alignment: .leading) {
                Text(media.code)
                    .font(.subheadline)
//                Text("\(media.time.formatted(.relative(presentation: .named)))")
                Text("\(media.time.formatted())")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MediaRow_Previews: PreviewProvider {
    static var previews: some View {
        MediaRow(media: .preview)
    }
}

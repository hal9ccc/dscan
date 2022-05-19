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

    @AppStorage("ServerURL")
    var serverurl = "http://localhost"
    
    var body: some View {
        print("\(serverurl)/media/files/\(media.img)")
        print("\(serverurl)/media/files/\(media.img.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? media.img)")
        
        return RoundedRectangle(cornerRadius: 4)
            .fill(.thinMaterial)
            .frame(width: 150, height: 150)
            .overlay {

                ZStack {
                    LazyImage(source: "\(serverurl)/media/files/\(media.img.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? media.img)", resizingMode: .aspectFit)
                        .frame(width: 150, height: 150)
                        .opacity(media.img == "␀" ? 0 : 1)

                    if media.imageData != nil {
                        let container = ImageContainer(image: UIImage(data: media.imageData!)!, type: .jpeg, data: media.imageData!)
                        Image(container)
                            .resizingMode(.aspectFit)
                            .opacity(media.imageData == nil ? 0 : 1)
                    }
                }
                .frame(width: 150, height: 150)
            }
    }
}

struct MediaThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        MediaThumbnail(media: .preview)
    }
}

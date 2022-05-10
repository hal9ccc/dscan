//
//  MediaZoom.swift
//  dscan
//
//  Created by Matthias Schulze on 10.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
#if os(iOS)
import NukeUI
#endif

struct MediaZoom: View {
    var media: Media

    @AppStorage("ServerURL")
    var serverurl = ""

    var body: some View {
        ZoomableScrollView {
            LazyImage(source: "\(serverurl)/media/files/\(media.img.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? media.img)"
//                      resizingMode: .aspectFit
            )
                .ignoresSafeArea()
            
//            Image("Your image here")
        }
        .navigationTitle (media.title)
    }
}

struct MediaZoom_Previews: PreviewProvider {
    static var previews: some View {
        ZoomableScrollView() {
            Text("ZoomableScrollView")
        }
    }
}

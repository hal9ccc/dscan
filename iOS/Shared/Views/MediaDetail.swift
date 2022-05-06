//
//  MediaDetail.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//


import Foundation
import SwiftUI
import SwiftUI

#if os(iOS)
import NukeUI
#endif

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct MediaDetail: View {
    var media: Media
    
    @EnvironmentObject var mediaProcessor: MediaProcessor
    
    var body: some View {
        ScrollView {
            VStack {
                ZStack {
                    LazyImage(source: media.img, resizingMode: .aspectFit)
                        .frame(height: 500)
                        .opacity(media.img == "␀" ? 0 : 1)

                    //let container = ImageContainer(image: UIImage(data: media.imageData!)!, type: .jpeg, data: media.imageData!)
                    if media.imageData != nil {
                        Image(UIImage(data: media.imageData!)!)
                            .resizingMode(.aspectFit)
                            .opacity(media.imageData == nil ? 0 : 1)
                    }
                
                }
                .frame(height: 500)
                
                
                if media.imageData != nil {
                    Button(action: { mediaProcessor.processImage(image: UIImage(data: media.imageData!)!, filename: media.filename, title: media.title, index: Int(media.idx), timestamp: "\(media.time)")}) {
                        Label("analyze & upload", systemImage: "mail.and.text.magnifyingglass")
                    }
                    .buttonStyle(GrowingButton())
                }
                

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
        .navigationTitle(title)
    }
    
    var title: String {
        media.code == "␀" ? media.filename : "\(media.carrier) #\(media.code)"
    }
}

struct MediaDetail_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetail(media: .preview)
    }
}

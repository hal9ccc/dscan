//
//  MediaDetail.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//


import Foundation
import SwiftUI

#if os(iOS)
import NukeUI
#endif

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct MediaDetail: View {
    @ObservedObject var media: Media

    @EnvironmentObject var mp: AppState
    

    var mediaProvider:      MediaProvider   = .shared

    @AppStorage("ServerURL")
    var serverurl = "http://localhost"
    
    @State private var isPresented = false
    
    var body: some View {
        print("MediaDetail \(media.filename)")
        
        return ScrollView {
            VStack {
                    ZStack {
                        LazyImage(source: "\(serverurl)/media/files/\(media.img.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? media.img)",
                                  resizingMode: .aspectFit
                        )
                            .frame(height: 500)
                            .opacity(media.img == "␀" ? 0 : 1)

                        if media.imageData != nil {
                            Image(UIImage(data: media.imageData!)!)
                                .resizingMode(.aspectFit)
                                .opacity(media.imageData == nil ? 0 : 1)
                        }

                    }
                    .onTapGesture() {
                        isPresented.toggle()
                    }
                    .frame(height: 500)
                
                    Text("\(media.fulltext)")
                        .padding()
                }

                if media.imageData != nil {
                    Button(action: {
                        mp.processImage (media, completion: {
                            Task {
                                do {
                                    try await mediaProvider.fetchMedia(pollingFor: 0)
                                } catch {
                                    print (error)
                                }
                                print ("Done.")
                            }
                        })
                                
                    }) {
                        Label("analyze & upload", systemImage: "mail.and.text.magnifyingglass")
                    }
                    .buttonStyle(GrowingButton())
                }


                Text(media.code)
                    .font(.title3)
                    .bold()

                Text("\(media.location)")
                    .foregroundStyle(Color.primary)

                Text("\(media.day)")
                    .foregroundStyle(Color.primary)

                Text("\(media.carrier)")
                    .foregroundStyle(Color.primary)

//                Text("\(media.time.formatted())")
//                    .foregroundStyle(Color.secondary)
                
                Text(media.description)

        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isPresented, content: { FullScreenModalView(media: media) } )
    }
    
    var title: String {
        media.code == "␀" ? media.filename : "\(media.carrier) #\(media.code)"
    }
    
//    func processImage(image: Data, filename: String, title: String, idx: Int, timestamp: Date ) {
//        mp.processImage(imageJpegData: image, filename: <#T##String#>, title: <#T##String#>, idx: <#T##Int#>, timestamp: <#T##Date#>: image, filename: filename, title: title, idx: idx, timestamp: timestamp)
//    }
}


struct FullScreenModalView: View {
    
    var media: Media
    
    @AppStorage("ServerURL")
    var serverurl = ""
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            ZoomableScrollView {
                ZStack {
                    LazyImage(source: "\(serverurl)/media/files/\(media.img.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? media.img)",
                        resizingMode: .aspectFit
                    )

                    if media.imageData != nil {
                        Image(UIImage(data: media.imageData!)!)
                            .resizingMode(.aspectFit)
                            .opacity(media.imageData == nil ? 0 : 1)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                .onEnded { value in
                    // swipe down gesture from https://stackoverflow.com/questions/60885532/how-to-detect-swiping-up-down-left-and-right-with-swiftui-on-a-view
                    switch(value.translation.width, value.translation.height) {
                        case (-100...100, 0...):
                            // down swipe
                            presentationMode.wrappedValue.dismiss()
                        default: break
                    }
                }
            )

            VStack {
                Button("Dismiss Modal") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .leading)
        }
    }
}


struct MediaDetail_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetail(media: .preview)
    }
}

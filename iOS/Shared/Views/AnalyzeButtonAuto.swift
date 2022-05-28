//
//  AnalyzeButtonAuto.swift
//  dscan
//
//  Created by Matthias Schulze on 18.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct AnalyzeButtonAuto: View {
    
    @EnvironmentObject var app: DScanApp
//    @Namespace private var animation
    
    var body: some View {
        if app.isUploading {
            ZStack(alignment: .top) { // HACK
//                Text("\(app.lastChange.formatted())").font(.caption).opacity(0)
                
                HStack {
                    Spacer()
                    Button(action: {} ) {
                        HStack (alignment: .center) {
                            Spacer()
                            ProgressView()
                            Text("Analyzing: \(app.numNew) ...")
                            Spacer()
                        }
                    }
                    .buttonStyle(GrowingButton())
                    .disabled(true)
                    Spacer()
                }
            }
        }
        else {
            AnalyzeButtonAutoView()
        }
    }
}


struct AnalyzeButtonAutoView: View {
    
    @EnvironmentObject var app: DScanApp
//    @Namespace private var animation
    
    @FetchRequest(
        entity: Media.entity(),
        sortDescriptors:    [NSSortDescriptor(key: "id", ascending: false)],
        predicate:          NSPredicate(format: "imageData != nil")
     ) var newMedia: FetchedResults<Media>

    var body: some View {
        if newMedia.count > 0 {
            ZStack(alignment: .topLeading) { // HACK
//                Text("\(app.lastChange.formatted())").font(.caption).opacity(0)

                HStack (alignment: .center) {
                    Spacer()
                    AnalyzeButton(count: newMedia.count) {
                        app.processAllImages(completion: { app.fetchMedia(pollingFor: 10) } )
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
    }
}

struct AnalyzeButtonAuto_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeButtonAuto()
    }
}

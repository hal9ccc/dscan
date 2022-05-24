//
//  MediaRow.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct MediaRow: View {
    @ObservedObject     var media:  Media
    @EnvironmentObject  var app:    DScanApp
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var body: some View {
//        print("MediaRow file: \(media.filename) carrier: \(media.carrier)")
//        print(String(describing: media.time))

        return VStack {
            HStack (alignment: .top) {
                MediaThumbnail(media: media)
                
                ZStack { // HACK
                    Text("\(app.lastChange.formatted())").font(.caption).opacity(0)

                    VStack (alignment: .leading) {

                        Label("\(media.code)", systemImage: "qrcode")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .if(media.code == "" || media.code == "␀") { view in view.hidden() }


                        
                        Spacer()
                        
                        Label("\(media.time.formatted())", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)

        //                Label("\(media.status)", systemImage: "checkmark.seal")
        //                    .font(.caption)
        //                    .foregroundStyle(.secondary)
        //                    .padding(.horizontal, 2)
        //                    .if(media.status == "" || media.status == "␀") { view in view.hidden() }
                        
                        StatusLabel (media: media)
                        
        //
        //                Text("Last Redraw \(app.lastRedraw.formatted())")
        //                    .foregroundColor(.secondary)
        //                    .padding()

                        Spacer()

                        VStack (alignment: .leading) {
                            Label("\(media.person)", systemImage: "person.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 2)
                                .if(media.person == "" || media.person == "␀") { view in view.hidden() }

                            Label("\(media.company)", systemImage: "person.2.crop.square.stack")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 2)
                                .if(media.company == "" || media.company == "␀") { view in view.hidden() }

                            Label("\(media.location)", systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 2)
                                .if(media.location == "" || media.location == "␀") { view in view.hidden() }


                            Label("\(media.carrier)", systemImage: "shippingbox")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 2)
                                .if(media.carrier == "" || media.carrier == "␀") { view in view.hidden() }
                        }

                        Spacer()
                        Spacer()

                    }
                    .frame(height: 160)
                }
                
                if idiom == .pad {
                    VStack {
                        InfoBox (info: media.info1)
                            .frame(width: 300)

                    }
                }
            }
            .frame(height: 160)
//            .padding (.horizontal, 0)

            JSONUI (input: media.info4)

            if idiom == .phone {
                InfoBox (info: media.info1)
            }
            
        }
    }
}

struct MediaRow_Previews: PreviewProvider {
    static var previews: some View {
        MediaRow(media: .preview)
    }
}

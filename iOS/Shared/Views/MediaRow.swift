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
        VStack  () {
            if media.code > "" && media.code != " - unbekannt -" {
                Label("\(media.code)", systemImage: "qrcode")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
//                    .padding(2)
//                    .background(.thinMaterial)
                    .foregroundStyle(.primary)

//                Divider()
//                    .frame(height: 1)
//                    .padding(0)
//                    .padding(.horizontal, 30)
//                    .background(Color.red)
            }
                
            HStack (alignment: .top) {
                MediaThumbnail(media: media)
                
                VStack (alignment: .leading) {
                    Label("\(media.time.formatted())", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)

                    if media.person > "" && media.person != " - unbekannt -" {
                        Label("\(media.person)", systemImage: "person.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)
                    }


                    if media.carrier > "" && media.carrier != " - unbekannt -" {
                        Label("\(media.carrier)", systemImage: "shippingbox")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)
                    }
                        

                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .padding (.horizontal, 0)

        }
        .frame(height: 150)
        .padding(0)

    }
}

struct MediaRow_Previews: PreviewProvider {
    static var previews: some View {
        MediaRow(media: .preview)
    }
}

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
        HStack (alignment: .top) {
            MediaThumbnail(media: media)
            
            VStack (alignment: .leading) {
                if media.code > "" && media.code != " - unbekannt -" {
                    Label("\(media.code)", systemImage: "qrcode")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.headline)
                        .foregroundStyle(.primary)

                }

                Spacer()

                Label("\(media.time.formatted())", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)

                Spacer()

                if media.person > "" && media.person != "␀"{
                    Label("\(media.person)", systemImage: "person.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                }

                if media.company > "" && media.company != "␀" {
                    Label("\(media.company)", systemImage: "person.2.crop.square.stack")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                }


                if media.carrier > "" && media.carrier != "␀" {
                    Label("\(media.carrier)", systemImage: "shippingbox")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                }

                Spacer()
                Spacer()

            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .padding (.horizontal, 0)

    }
}

struct MediaRow_Previews: PreviewProvider {
    static var previews: some View {
        MediaRow(media: .preview)
    }
}

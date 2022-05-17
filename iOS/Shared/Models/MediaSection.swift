//
//  MediaSort.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

struct MediaSection: Hashable, Identifiable, Equatable {
    let id:           Int
    let name:         String
    let icon:         String
    let descriptors:  [SortDescriptor<Media>]
    let section:      KeyPath<Media, String>

    static let sorts: [MediaSection] = [
        MediaSection (
            id:         0,
            name:       "Alle",
            icon:       "asterisk.circle",
            descriptors:[
                SortDescriptor (\Media.type),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.type
        ),
        MediaSection (
            id:         1,
            name:       "Tag",
            icon:       "calendar",
            descriptors:[
                SortDescriptor (\Media.day, order: .reverse),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.day
        ),
        MediaSection (
            id:         2,
            name:       "Status",
            icon:       "checkmark.seal",
            descriptors:[
                SortDescriptor (\Media.status),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.status
        ),
        MediaSection (
            id:         3,
            name:       "Person",
            icon:       "person",
            descriptors:[
                SortDescriptor (\Media.person),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.person
        ),
        MediaSection (
            id:         4,
            name:       "Firma",
            icon:       "building.2.crop.circle",
            descriptors:[
                SortDescriptor (\Media.company),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.company
        ),
        MediaSection (
            id:         5,
            name:       "Ort",
            icon:       "mappin.and.ellipse",
            descriptors:[
                SortDescriptor (\Media.location),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.location
        ),
        MediaSection (
            id:         6,
            name:       "Typ",
            icon:       "list.bullet.circle",
            descriptors:[
                SortDescriptor (\Media.type),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.type
        ),
        MediaSection(
            id:         7,
            name:       "Gerät",
            icon:       "iphone.homebutton",
            descriptors:[
                SortDescriptor (\Media.device),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.device
        ),
        MediaSection(
            id:         8,
            name:       "Spedition",
            icon:       "shippingbox",
            descriptors:[
                SortDescriptor (\Media.carrier),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.carrier
        ),
        MediaSection(
            id:         9,
            name:       "Tracking-Nr.",
            icon:       "number.circle",
            descriptors:[
                SortDescriptor (\Media.code),
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.code
        )
    ]

    static var `default`    : MediaSection { sorts[0] }
    static var `all`        : MediaSection { sorts[0] }
    static var `day`        : MediaSection { sorts[1] }
    static var `status`     : MediaSection { sorts[2] }
}


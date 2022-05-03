//
//  MediaSort.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

struct MediaSort: Hashable, Identifiable {
    let id:           Int
    let name:         String
    let descriptors:  [SortDescriptor<Media>]
    let section:      KeyPath<Media, String>

    static let sorts: [MediaSort] = [
        MediaSort (
            id:         0,
            name:       "by Date/Time",
            descriptors:[
                SortDescriptor (\Media.time, order: .reverse),
                SortDescriptor (\Media.set,  order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.set
        ),
        MediaSort (
            id:         1,
            name:       "by Person",
            descriptors:[
                SortDescriptor (\Media.person),
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.person
        ),
        MediaSort (
            id:         2,
            name:       "by Company",
            descriptors:[
                SortDescriptor (\Media.company),
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.company
        ),
        MediaSort(
            id:         3,
            name:       "by Carrier",
            descriptors:[
                SortDescriptor (\Media.carrier),
                SortDescriptor (\Media.set, order: .reverse),
                SortDescriptor (\Media.idx),
            ],
            section:    \Media.carrier
        ),
        MediaSort (
            id:         4,
            name:       "by Location",
            descriptors:[
                SortDescriptor (\Media.location),
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.location
        ),
        MediaSort(
            id:         5,
            name:       "by Device",
            descriptors:[
                SortDescriptor (\Media.device),
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.idx),
            ],
            section:    \Media.device
        )
    ]

    static var `default`: MediaSort { sorts[0] }
}


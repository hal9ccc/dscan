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
            name:       "Time - descending",
            descriptors:[
                SortDescriptor (\Media.set, order: .reverse),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.set
        ),
        MediaSort (
            id:          1,
            name:       "Time - ascending",
            descriptors:[
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.set
        ),
        MediaSort(
            id:         2,
            name:       "by Carrier",
            descriptors:[
                SortDescriptor (\Media.carrier),
                SortDescriptor (\Media.set, order: .reverse),
                SortDescriptor (\Media.idx),
            ],
            section:    \Media.carrier
        ),
        MediaSort(
            id:         3,
            name:       "by Carrier, newest first",
            descriptors:[
                SortDescriptor (\Media.carrier),
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.idx),
            ],
            section:    \Media.carrier
        )
    ]

    static var `default`: MediaSort { sorts[0] }
}


//
//  MediaSort.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

struct MediaSort: Hashable, Identifiable, Equatable {
    let id:           Int
    let name:         String
    let descriptors:  [SortDescriptor<Media>]
    let section:      KeyPath<Media, String>

    static let sorts: [MediaSort] = [
        MediaSort (
            id:         0,
            name:       "all",
            descriptors:[
                SortDescriptor (\Media.set),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.set
        ),
        MediaSort (
            id:         1,
            name:       "by Status",
            descriptors:[
                SortDescriptor (\Media.status),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.status
        ),
        MediaSort (
            id:         2,
            name:       "by Type",
            descriptors:[
                SortDescriptor (\Media.type),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.type
        ),
        MediaSort (
            id:         3,
            name:       "by Person",
            descriptors:[
                SortDescriptor (\Media.person),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.person
        ),
        MediaSort (
            id:         4,
            name:       "by Company",
            descriptors:[
                SortDescriptor (\Media.company),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.company
        ),
        MediaSort(
            id:         5,
            name:       "by Carrier",
            descriptors:[
                SortDescriptor (\Media.carrier),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.carrier
        ),
        MediaSort (
            id:         6,
            name:       "by Location",
            descriptors:[
                SortDescriptor (\Media.location),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.location
        ),
        MediaSort(
            id:         7,
            name:       "by Device",
            descriptors:[
                SortDescriptor (\Media.device),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.device
        ),
        MediaSort(
            id:         8,
            name:       "by Code",
            descriptors:[
                SortDescriptor (\Media.code),
                SortDescriptor (\Media.time),
                SortDescriptor (\Media.idx)
            ],
            section:    \Media.code
        )
    ]

    static var `default`: MediaSort { sorts[0] }
}


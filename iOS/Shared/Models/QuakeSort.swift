//
//  QuakeSort.swift
//  Earthquakes
//
//  Created by Matthias Schulze on 12.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

struct QuakeSort: Hashable, Identifiable {
    let id:           Int
    let name:         String
    let descriptors:  [SortDescriptor<Quake>]
    let section:      KeyPath<Quake, String>

    static let sorts: [QuakeSort] = [
      QuakeSort (
            id:         0,
            name:       "Time - descending",
            descriptors:[
                SortDescriptor (\Quake.type),
                SortDescriptor (\Quake.time, order: .reverse)
            ],
            section:    \Quake.type
        ),
        QuakeSort (
            id:          1,
            name:       "Time - ascending",
            descriptors:[
                SortDescriptor (\Quake.type),
                SortDescriptor (\Quake.time, order: .forward)
            ],
            section:    \Quake.type
        ),
        QuakeSort(
            id:         2,
            name:       "Magnitude - descending",
            descriptors:[
                SortDescriptor (\Quake.type),
                SortDescriptor (\Quake.magnitude, order: .reverse)
            ],
            section:    \Quake.type
        ),
        QuakeSort(
            id:         3,
            name:       "Magnitude - ascending",
            descriptors:[
                SortDescriptor (\Quake.type),
                SortDescriptor( \Quake.magnitude, order: .forward)
            ],
            section:    \Quake.type
        )
    ]

    static var `default`: QuakeSort { sorts[0] }
}


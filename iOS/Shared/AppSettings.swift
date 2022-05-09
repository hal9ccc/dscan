//
//  Settings.swift
//  dscan
//
//  Created by Matthias Schulze on 04.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

class AppSettings: ObservableObject {
    @Published var sort: MediaSort = MediaSort.default
//    @Published var section: String = ""
}

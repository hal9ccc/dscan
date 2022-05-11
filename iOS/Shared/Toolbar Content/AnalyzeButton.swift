//
//  AnalyzeButton.swift
//  dscan
//
//  Created by Matthias Schulze on 10.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

import SwiftUI

struct AnalyzeButton: View {
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Label("Analyze all", systemImage: "wand.and.stars")
        }
//        .keyboardShortcut(.delete, modifiers: [])
    }
}

struct AnalyzeButton_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeButton()
    }
}

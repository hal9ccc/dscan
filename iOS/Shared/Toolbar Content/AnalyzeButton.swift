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
    let count: Int;
    var action: () -> Void = {}
    
    @EnvironmentObject  var app:    DScanApp
    
    var body: some View {
        ZStack(alignment: .topLeading) { // HACK
//            Text("\(app.lastChange.formatted())").font(.caption).opacity(0)

            Button(action: action) {
                Label("Analyze \(count) new scans", systemImage: "wand.and.stars")
            }
            .buttonStyle(GrowingButton())
    //        .padding()
    //        .keyboardShortcut(.delete, modifiers: [])
        }
    }
}

struct AnalyzeButton_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeButton(count: 2)
    }
}

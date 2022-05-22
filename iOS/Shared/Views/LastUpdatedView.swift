//
//  AnalyzeButtonAuto.swift
//  dscan
//
//  Created by Matthias Schulze on 18.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct LastUpdatedView: View {
    
    @EnvironmentObject var app: DScanApp
    let updateTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var i = 0
    
    var body: some View {
        ZStack {
            HStack (alignment: .center) {
                Spacer()

                Text("Letzte Änderung \(app.lastChange.formatted(.relative(presentation: .named)))")
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .padding()
                    
                Spacer()
            }
            Text("\(i)")
                .opacity(0)
        }
        .listRowBackground(Color.clear)
        .onReceive(updateTimer) { input in
            i = i + 1
        }
    }
}


struct LastUpdatedView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeButtonAuto()
    }
}

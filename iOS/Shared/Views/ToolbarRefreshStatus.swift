//
//  ToolbarRefreshStatus.swift
//  dscan
//
//  Created by Matthias Schulze on 24.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct ToolbarRefreshStatus: View {
    @EnvironmentObject  var app:    DScanApp
    
    @AppStorage("AutoUpdate")
    private var autoUpdate: Bool = true

    @AppStorage("LongpollMode")
    private var longpollMode: Bool = true
    
    @AppStorage("LongpollSeconds")
    private var longpollSeconds: Double = 60
    
    var body: some View {
        let secondsSincelastChange  = Date.now.timeIntervalSinceReferenceDate - app.lastChange.timeIntervalSinceReferenceDate
        let lpm = secondsSincelastChange < longpollSeconds ? longpollMode : false

        ZStack {
            Label("Sync", systemImage: autoUpdate && lpm ? "arrow.left.arrow.right.circle.fill" : "arrow.clockwise")
                .foregroundStyle(!autoUpdate || !lpm ? Color.accentColor : Color.primary)
                .opacity(app.isLoading ? 0 : 1)
                .onTapGesture {
                    print("onTapGesture Label")
                    if !autoUpdate || !lpm {
                        app.fetchMedia(pollingFor: 0)
                    }
                }
                .onLongPressGesture {
                    print("onLongPressGesture Label")
                    autoUpdate.toggle()
                    app.changeOccured()
                }
            
            ProgressView()
                .opacity(app.isLoading ? 1 : 0)

            //                Label("Sync", systemImage: "arrow.left.arrow.right.circle.fill")
//                    .opacity(!app.isSync || app.isLoading ? 0 : 1)
//
            Text("A")
                .font(.system(size: 6))
                .foregroundStyle(Color.secondary)
                .opacity(autoUpdate && !app.isSync && !app.isLoading && !longpollMode ? 1 : 0)

//            RefreshButton {
//                app.fetchMedia(pollingFor: 0)
//            }
//            .opacity(app.isLoading || app.isSync ? 0 : 1)
//            .disabled(app.isLoading)
        }
        .onLongPressGesture {
            print("onLongPressGesture ZStack")
            autoUpdate.toggle()
            app.changeOccured()
        }

    }
}

struct ToolbarRefreshStatus_Previews: PreviewProvider {
    static var previews: some View {
//        ToolbarRefreshStatus()
        Text("später")
    }
}

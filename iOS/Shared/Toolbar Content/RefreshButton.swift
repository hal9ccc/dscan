/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The refresh button of the app.
*/

import SwiftUI

struct RefreshButton: View {
    var action: () -> Void = {}
    
    @EnvironmentObject  var app:    DScanApp
    
    @AppStorage("AutoUpdate")
    private var autoUpdate: Bool = true
    
    var body: some View {
        Button(action: action) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .onLongPressGesture {
            print("onLongPressGesture RefreshButton")
            autoUpdate.toggle()
            app.changeOccured()
        }
        .keyboardShortcut("r")
    }
}

struct RefreshButton_Previews: PreviewProvider {
    static var previews: some View {
        RefreshButton()
    }
}

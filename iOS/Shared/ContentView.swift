/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The views of the app, which display details of the fetched earthquake data.
*/

import SwiftUI
import CoreData
import OSLog

struct ContentView: View {

//    let logger = Logger(subsystem: "com.example.apple-samplecode.Earthquakes", category: "view")

    var body: some View {

        TabView {

            MediaView()
                .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
                .tabItem {
                    Label("Media", systemImage: "doc.on.doc")
                }

            QuakeView()
                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
                .tabItem {
                    Label("Quakes", systemImage: "list.dash")
                }

            ScanView()
//                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }


        }

    }
}

// MARK: Toolbar Content

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

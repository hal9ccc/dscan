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
    @StateObject var scanData = ScanData()
    

    var body: some View {

        TabView {

            MediaView()
                .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
                .tabItem {
                    Label("Documents", systemImage: "doc.on.doc")
                }

            ScannerView(completion: {
                scanData in
                print("got \(scanData?.count ?? 0) scans")
                
    //            if let outputText = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines){
    //                let newScanData = ScanDataOrig(content: outputText)
    //                self.texts.append(newScanData)
    //            }
//                print (mediaProperties)
//                self.showScannerSheet = false
            })
            .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
            .tabItem {
                Label("scan", systemImage: "doc.text.viewfinder")
            }

//            QuakeView()
//                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
//                .tabItem {
//                    Label("Quakes", systemImage: "globe")
//                }
//
            ScanView()
//                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }


        }
        .environmentObject(scanData)

    }
}

// MARK: Toolbar Content

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

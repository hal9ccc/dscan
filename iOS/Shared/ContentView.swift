/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The views of the app, which display details of the fetched earthquake data.
*/

import SwiftUI
import CoreData
import OSLog
import Nuke
//import NukeUI


struct ContentView: View {

//    let logger = Logger(subsystem: "com.example.apple-samplecode.Earthquakes", category: "view")
    @StateObject var scanData = ScanData()
    

    var body: some View {

        TabView {

            MediaSectionList()
                .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
                .tabItem {
                    Label("Documents", systemImage: "doc.on.doc")
                }

//            ScannerView(completion: {
//                scanData in
//
//                print("got \(scanData?.count ?? 0) scans")
//
//                let mediaProvider:      MediaProvider   = .shared
//
//                Task {
//                    // Import the JSON into Core Data.
//                    print("Start importing data to the store...")
//
//                    do {
//                        try await mediaProvider.importMedia(from: scanData!)
//                        print("Done!")
//                    }
//                    catch {
//                        print(error)
//                    }
//               }
                
//            })
//            .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
//            .tabItem {
//                Label("scan", systemImage: "doc.text.viewfinder")
//            }

            QuakeView()
                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
                .tabItem {
                    Label("Quakes", systemImage: "globe")
                }

            SettingsView()
//                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }

            
            
            
            
            
            
            
            

        }
        .environmentObject(scanData)
        .onAppear() {


            // configure NukeUI Image Loading Options
            // from https://www.raywenderlich.com/11070743-nuke-tutorial-for-ios-getting-started
            let contentModes = ImageLoadingOptions.ContentModes(
              success: .scaleAspectFill,
              failure: .scaleAspectFit,
              placeholder: .scaleAspectFit)

            ImageLoadingOptions.shared.placeholder = UIImage(named: "dark-moon")
            ImageLoadingOptions.shared.failureImage = UIImage(named: "annoyed")
            ImageLoadingOptions.shared.transition = .fadeIn(duration: 2.5)
            ImageLoadingOptions.shared.contentModes = contentModes

            DataLoader.sharedUrlCache.diskCapacity = 0

            let pipeline = ImagePipeline {
              let dataCache = try? DataCache(name: "de.hal9ccc.dscan.datacache")
              dataCache?.sizeLimit = 200 * 1024 * 1024
              $0.dataCache = dataCache
            }
            ImagePipeline.shared = pipeline
        }

    }
}

// MARK: Toolbar Content

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

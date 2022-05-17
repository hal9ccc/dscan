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
    @StateObject var mediaProcessor = MediaProcessor()
    let mediaProvider:      MediaProvider   = .shared

//    @StateObject var settings = AppSettings()
//    @StateObject var scanData = ScanData()
    
    @AppStorage("CacheSize")
    private var cachesize: Double = 50
    
    @State private var primaryViewSelection: String? = nil
    @State private var showScannerSheet = false

    @State private var isLoading = false

    var body: some View {

        NavigationView {
            VStack {
                SectionList()
//                    .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)

                
                //            ScannerView(completion: { scanData in
    //                mediaProvider.importSet(scanData)
    //            })
    //            .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
    //            .tabItem {
    //                Label("scan", systemImage: "doc.text.viewfinder")
    //            }


    //            QuakeView()
    //                .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
    //                .tabItem {
    //                    Label("Quakes", systemImage: "globe")
    //                }
    //
    //            SettingsView()
    //                .tabItem {
    //                    Label("Settings", systemImage: "gear")
    //                }

            }
            
        }
        .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
        .toolbar (content: toolbarContent)
        .environmentObject(mediaProcessor)
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
              dataCache?.sizeLimit = Int(cachesize)
              $0.dataCache = dataCache
            }
            ImagePipeline.shared = pipeline
        }
        .sheet(isPresented: $showScannerSheet, content: {
            self.makeScannerView()
        })

   }

   private func makeScannerView()-> some View {
       ScannerView(completion: { scanData in
           mediaProvider.importSet(scanData)
           self.showScannerSheet = false
       })
   }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        #if os(iOS)
        toolbarContent_iOS()
        #else
        toolbarContent_macOS()
        #endif
    }

    #if os(iOS)
    @ToolbarContentBuilder
    private func toolbarContent_iOS() -> some ToolbarContent {

        ToolbarItemGroup(placement: .bottomBar) {
            if (isLoading) {
                ProgressView()
            }
            else {
                RefreshButton {
                    Task {
                        //await fetchMedia()
                    }
                }
                .disabled(isLoading)
            }

            Spacer()

            ToolbarStatus(
                itemCount: 0,
                isLoading: isLoading,
                lastUpdated: 4,
                sectionCount: 23,
                selectedCount: 0
            )

            Spacer()

//            Button(action: {
//                self.showScannerSheet = true
//            }, label: {
//                Image(systemName: "doc.text.viewfinder")
//            })

        }
    }
    #else
    @ToolbarContentBuilder
    private func toolbarContent_macOS() -> some ToolbarContent {

        ToolbarItemGroup(placement: .status) {
            SortSelectionView (selectedSortItem: $selectedSort, sorts: MediaSort.sorts)

            onChange(of: selectedSort) { _ in
                //let config = media
//                print (selectedSort.descriptors)
//                print (selectedSort.section)
                media.sortDescriptors = selectedSort.descriptors
                media.sectionIdentifier = selectedSort.section
            }

            ToolbarStatus(
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: media.count,
                itemCount: media.joined().count
            )
        }

        ToolbarItemGroup(placement: .navigation) {
            HStack {
                ProgressView()

                RefreshButton {
                    Task {
                        await fetchMedia()
                    }
                }
                .hidden(isLoading)
                
                Spacer()
                
                DeleteButton {
                    Task {
                        await deleteMedia(for: selection)
                    }
                }
                .disabled(isLoading || selection.isEmpty)
                
                Spacer()
            }
        }
    }
    #endif

               
}

// MARK: Toolbar Content

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

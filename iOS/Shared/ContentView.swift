/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The views of the app, which display details of the fetched earthquake data.
*/

import UIKit
import SwiftUI
import CoreData
import OSLog
import Nuke
//import NukeUI


struct ActivityIndicator: UIViewRepresentable {
    
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    fileprivate var configuration = { (indicator: UIView) in }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}


extension View where Self == ActivityIndicator {
    func configure(_ configuration: @escaping (Self.UIView)->Void) -> Self {
        Self.init(isAnimating: self.isAnimating, configuration: configuration)
    }
}



struct ContentView: View {

//    let logger = Logger(subsystem: "com.example.apple-samplecode.Earthquakes", category: "view")
    @StateObject        var app: DScanApp
    let mediaProvider:      MediaProvider   = .shared

    @AppStorage("CacheSize")
    private var cachesize: Double = 50
    
    @State private var primaryViewSelection: String? = nil
    @State private var showScannerSheet = false
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

//    @State private var isLoading = false

    var body: some View {

        NavigationView {
            VStack {
                SectionList()
//                    .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
            }
            
        }
        .toolbar (content: toolbarContent)

        // SwiftUI NavigationView pops back when updating observableObject
        // https://developer.apple.com/forums/thread/693137
        .if(idiom == .phone) { v in v.navigationViewStyle(.stack)}
        
        .environment(\.managedObjectContext, MediaProvider.shared.container.viewContext)
        .environmentObject(app)

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
            ZStack {
                ActivityIndicator(isAnimating: app.isLoading)
                    .configure { $0.color = UIColor.yellow } // Optional configurations (🎁 bouns)
                    .background(Color.blue)
                    .if(!app.isLoading && !app.isSync) { v in v.hidden() }

//                ProgressView()
//                    .opacity(app.isLoading ? 1 : 0)

                RefreshButton {
                    app.fetchMedia(pollingFor: 0)
                }
                .opacity(app.isLoading ? 0 : 1)
                .disabled(app.isLoading)
            }

            Spacer()

            ToolbarStatus(
                lastUpdated:    app.lastUpdated,
                section:        app.section,
                sectionKey:     app.sectionKey,
                itemCount:      app.numItems,
                isLoading:      app.isLoading,
                sectionCount:   app.numSections,
                showingCount:   app.numShowing,
                selectedCount:  app.numSelected
            )

            Spacer()

            Button(action: {
                self.showScannerSheet = true
            }, label: {
                Image(systemName: "doc.text.viewfinder")
            })

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
        ContentView(app: DScanApp())
    }
}

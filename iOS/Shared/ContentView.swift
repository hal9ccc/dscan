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
    
    @State private var primaryViewSelection: String?    = nil
    @State private var showScannerSheet                 = false
    @State private var showWebView                      = false
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    let syncTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

//    @State private var isLoading = false

    var body: some View {

        NavigationView {
            ZStack {
                Color.green
                    .opacity(0.1)
                    .ignoresSafeArea()
            
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

        // makes the UI update once per second
        .onReceive(syncTimer) { input in
            app.onSyncTimer()
        }
        .sheet(isPresented: $showScannerSheet) {
            self.makeScannerView()
        }
        
        .sheet(isPresented: $app.webviewOn) {
            WebView(url: app.webviewUrl)
        }
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
            ToolbarRefreshStatus()
            
            Spacer()

            ToolbarStatus(
                lastChange:     app.lastChange,
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

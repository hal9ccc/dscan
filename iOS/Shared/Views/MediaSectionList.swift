//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

    
struct MediaSectionList: View {
    
    let mediaProvider:      MediaProvider   = .shared
    
    @SectionedFetchRequest (
        sectionIdentifier:  MediaSort.default.section,
        sortDescriptors:    MediaSort.default.descriptors,
        predicate:          NSPredicate(format: "hidden == false"),
        animation:          .default
    )
    private var media: SectionedFetchResults<String, Media>

    @State private var mediaSelection: Set<String> = []

    @State private var error: DscanError?
    @State private var hasError = false
    
    @State private var selectedMediaSort: MediaSort = MediaSort.default
    @State private var mediaSearchTerm = ""
    @State private var isLoading = false
    @State private var lastSortChange: Date = Date()
    
    @State private var showScannerSheet = false
    @State private var texts:[ScanDataOrig] = []
    

//    @State
    @AppStorage("lastSelectedSort")
    private var lastSelectedSort = MediaSort.default.id

    @AppStorage("lastSelectedSection")
    private var lastSelectedSection = ""

    @AppStorage("lastUpdatedMedia")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970
    

    var body: some View {

        let request = media
        request.sectionIdentifier = MediaSort.sorts[lastSelectedSort].section
        request.sortDescriptors   = MediaSort.sorts[lastSelectedSort].descriptors
        print("MediaSectionList \(MediaSort.sorts[lastSelectedSort].name) -> \(lastSelectedSection)")

        return NavigationView {
            
            ZStack {
                
                List() {
                    
                    ForEach(media) { section in
                        
                        NavigationLink(destination: MediaList(sortId: selectedMediaSort.id, section: section.id)) {
                            SectionHeader(name: "\(section.id != "␀" ? section.id : " unbekannt ")", pill:section.count)
                        }
                    }
                } // List
                .listStyle(SidebarListStyle())
                .searchable(text: mediaSearchQuery)
                .navigationTitle (title)
                .toolbar (content: toolbarContent)

        #if os(iOS)
                .refreshable { await fetchMedia() }
        #else
                .frame(minWidth: 320)
        #endif

                // so that the view refreshes when the sort is changed
                Text("\(lastSortChange)")
                    .hidden()

            }
            .sheet(isPresented: $showScannerSheet, content: {
                self.makeScannerView()
            })

        }
        .onAppear {
            selectedMediaSort = MediaSort.sorts[lastSelectedSort]
        }
        .alert(isPresented: $hasError, error: error) { }
        
//        return MediaList(sortId: selectedMediaSort.id, section: lastSelectedSection)

    }
    
    var title: String {
        return selectedMediaSort.name
    }

    var mediaSearchQuery: Binding<String> {
      Binding {
        mediaSearchTerm
      } set: { newValue in
        mediaSearchTerm = newValue
        
        guard !newValue.isEmpty else {
          media.nsPredicate = nil
          return
        }

        media.nsPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [
                NSPredicate (format: "code contains[cd] %@", newValue),
                NSPredicate (format: "device contains[cd] %@", newValue),
                NSPredicate (format: "person contains[cd] %@", newValue),
                NSPredicate (format: "company contains[cd] %@", newValue),
                NSPredicate (format: "carrier contains[cd] %@", newValue),
                NSPredicate (format: "location contains[cd] %@", newValue)
        ])
      }
    }

    
    private func makeScannerView()-> some View {
        ScannerView(completion: { scanData in
            mediaProvider.importSet(scanData)
            self.showScannerSheet = false
        })
    }
    

    private func fetchMedia() async {
        isLoading = true
        do {
            try await mediaProvider.fetchMedia()
            lastUpdated = Date().timeIntervalSince1970
        } catch {
            self.error = error as? DscanError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        isLoading = false
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
        ToolbarItem(placement: .primaryAction) {
            MediaSortSelection (selectedSortItem: $selectedMediaSort, sorts: MediaSort.sorts)
            onChange(of: selectedMediaSort) { _ in
                // that let is there for a reason!
                // vvvvvvvv see https://www.raywenderlich.com/27201015-dynamic-core-data-with-swiftui-tutorial-for-ios
                let request = media
                request.sectionIdentifier = selectedMediaSort.section
                request.sortDescriptors   = selectedMediaSort.descriptors
                lastSelectedSort = selectedMediaSort.id
                lastSortChange = Date()
                print("sort \(selectedMediaSort.name) was selected")
            }
        }

        ToolbarItemGroup(placement: .bottomBar) {
            if (isLoading) {
                ProgressView()
            }
            else {
                RefreshButton {
                    Task {
                        await fetchMedia()
                    }
                }
                .disabled(isLoading)
            }

            Spacer()

            ToolbarStatus(
                itemCount: media.joined().count,
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: media.count,
                selectedCount: 0
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
                print (selectedSort.descriptors)
                print (selectedSort.section)
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

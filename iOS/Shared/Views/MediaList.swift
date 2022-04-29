//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

    
struct MediaList: View {
    @EnvironmentObject var scanData: ScanData

    var selectedSort:       MediaSort
    var section:            String

    var mediaProvider:      MediaProvider   = .shared
    
    @SectionedFetchRequest (
        sectionIdentifier: MediaSort.default.section,
        sortDescriptors: MediaSort.default.descriptors,
        animation: .default
    )
    private var media: SectionedFetchResults<String, Media>

    @State private var mediaSelection: Set<String> = []

    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    @State private var selectMode: SelectMode = .inactive
    #endif

    @State private var error: DscanError?
    @State private var hasError = false
    
//    @State private var selectedMediaSort: MediaSort = MediaSort.default
    @State private var mediaSearchTerm = ""
    @State private var isLoading = false
    @State private var lastSortChange: Date = Date()
    
    @State private var showScannerSheet = false
    @State private var texts:[ScanDataOrig] = []
    
//    @AppStorage("lastSelectedSection")
//    private var lastSelectedSection = ""

    @AppStorage("lastUpdatedMedia")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970


    var body: some View {

        print("rendering section \(section)")
        print(selectedSort.section)
        print(selectedSort.descriptors)
        
        return ZStack {
           
            List(selection: $mediaSelection) {
                
                ForEach(media) { sect in
                    
                    if sect.id == section {
                   
                        ForEach(sect, id: \.id) { media in
                            NavigationLink(destination: MediaDetail(media: media)) {
                                MediaRow(media: media)
                            }
                        }
                        .onDelete { indexSet in
                            withAnimation { deleteMediaByOffsets (from: sect, at: indexSet) }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: mediaSearchQuery)
            .navigationTitle (title)
            .toolbar (content: toolbarContent)

    #if os(iOS)
            .environment(\.editMode, $editMode)
            .refreshable { await fetchMedia() }
    #else
            .frame(minWidth: 320)
    #endif

            // so that the view refreshes when the sort is changed
            Text("\(lastSortChange)")
                .hidden()

        }
        .onAppear {
            let request = media
            request.sectionIdentifier = selectedSort.section
            request.sortDescriptors = selectedSort.descriptors
            lastSortChange = Date()
//            lastSelectedSection = section
            print("MediaList \(selectedSort.name) -> \(section) appeared")
        }
            
    }

    
    var title: String {
        #if os(iOS)
        print ("section is now \(section)")
        if selectMode.isActive || mediaSelection.isEmpty {
            return "\(section != "␀" ? section : " unbekannt ")"
        } else {
            return "\(mediaSelection.count) Selected"
        }
        #else
        return "\(section != "␀" ? section : " unbekannt ")"
        #endif
    }

    var mediaSearchQuery: Binding<String> {
        
      let f = Binding {
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
        
        print("binding", f)
       
        return f
    }

    
    private func makeScannerView()-> some View {
        ScannerView(completion: {
            mediaProperties in
//            if let outputText = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines){
//                let newScanData = ScanDataOrig(content: outputText)
//                self.texts.append(newScanData)
//            }
//            print (mediaProperties)
            self.showScannerSheet = false
        })
        .environmentObject(scanData)
    }
    
                             
    private func deleteMediaByOffsets(from section: SectionedFetchResults<String, Media>.Element, at offsets: IndexSet) {
        let objectIDs = offsets.map { section[$0].objectID }
        mediaProvider.deleteMedia(identifiedBy: objectIDs)
        mediaSelection.removeAll()
    }

    private func deleteMedia(for codes: Set<String>) async {
        do {
            let mediaToDelete = media.joined().filter { codes.contains($0.id) }
            print ("deleting \(mediaToDelete.count) media...")
            try await mediaProvider.deleteMedia(mediaToDelete)
        } catch {
            self.error = error as? DscanError ?? .unexpectedError(error: error)
            self.hasError = true
        }

        mediaSelection.removeAll()
        #if os(iOS)
        editMode = .inactive
        #endif
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
//        ToolbarItem(placement: .primaryAction) {
//            MediaSortSelection (selectedSortItem: $selectedMediaSort, sorts: MediaSort.sorts)
//            onChange(of: selectedMediaSort) { _ in
//                // that let is there for a reason!
//                // vvvvvvvv see https://www.raywenderlich.com/27201015-dynamic-core-data-with-swiftui-tutorial-for-ios
//                let request = media
//                request.sectionIdentifier = selectedMediaSort.section
//                request.sortDescriptors = selectedMediaSort.descriptors
//                lastSortChange = Date()
//            }
//        }
//
        ToolbarItem(placement: .primaryAction) {
            if editMode == .active {
                SelectButton(mode: $selectMode) {
                    if selectMode.isActive {
                        mediaSelection = Set(media.joined().map { $0.id })
//                        mediaSelection = Set(media.first(where: section))
                    } else {
                        mediaSelection = []
                    }
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            EditButton(editMode: $editMode) {
                mediaSelection.removeAll()
                editMode = .inactive
                selectMode = .inactive
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
                .disabled(isLoading || editMode == .active)
            }

            Spacer()

            ToolbarStatus(
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: media.count,
                itemCount: media.joined().count
            )

            Spacer()

            if editMode == .active {
                DeleteButton {
                    Task {
                        await deleteMedia(for: mediaSelection)
                        selectMode = .inactive
                    }
                }
                .disabled(isLoading || mediaSelection.isEmpty)
            }
            
//            if editMode != .active {
//                Button(action: {
//                    self.showScannerSheet = true
//                }, label: {
//                    Image(systemName: "doc.text.viewfinder")
//                })
//            }
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
            }
        }
    }
    #endif


}

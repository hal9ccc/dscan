//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI


struct MediaList: View {
    let sortId:  Int
    let section: String


    @EnvironmentObject var mp: MediaProcessor

    var mediaProvider:      MediaProvider   = .shared

    @SectionedFetchRequest (
        sectionIdentifier:  MediaSection.default.section,
        sortDescriptors:    MediaSection.default.descriptors,
        predicate:          NSPredicate(format: "hidden == false"),
        animation:          .default
    )
    private var media: SectionedFetchResults<String, Media>

    @FetchRequest(
        entity: Media.entity(),
        sortDescriptors:    [NSSortDescriptor(key: "id", ascending: false)],
        predicate:          NSPredicate(format: "imageData != nil")
     ) var newMedia: FetchedResults<Media>

    @State private var mediaSelection: Set<String> = []

    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    @State private var selectMode: SelectMode = .inactive
    #endif

    @State private var error: DscanError?
    @State private var hasError = false

    @State private var mediaSearchTerm = ""
    @State private var isLoading       = false
    @State private var lastSortChange: Date = Date()

    let polltimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var longPollMode   = true
    @State private var maxCid         = -1   // last known Change-ID
    @State private var pollSec        = 10
    @State private var isPolling      = false
    @State private var nextPollIn     = 10
    @State private var pollFailure    = false

    @State private var showScannerSheet = false
    @State private var texts:[ScanDataOrig] = []

    @AppStorage("lastUpdatedMedia")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970


    /*
    ** ********************************************************************************************
    */
    var body: some View {

        let request = media
        request.sectionIdentifier = MediaSection.sorts[sortId].section
        request.sortDescriptors   = MediaSection.sorts[sortId].descriptors
        print("MediaList \(MediaSection.sorts[sortId].name) -> \(section)")

        return ZStack {

            List(selection: $mediaSelection) {

                ForEach(media) { sect in

                    if sect.id == section {

                        ForEach(sect, id: \.filename) { media in
                            NavigationLink(destination: MediaDetail(media: media)) {
                                MediaRow(media: media)
                            }.listRowBackground(Color.clear)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar (content: toolbarContent)

    #if os(iOS)
            .environment(\.editMode, $editMode)
            .refreshable { await fetchMedia(complete: true) }
    #else
            .frame(minWidth: 320)
    #endif

            // so that the view refreshes when the sort is changed
            Text("\(lastSortChange)")
                .hidden()

        }
        .background(
            LinearGradient(
                stops: [SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0), SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .alert(isPresented: $hasError, error: error) { }
        .sheet(isPresented: $showScannerSheet, content: {
            self.makeScannerView()
        })
        .onReceive(polltimer) { input in
            // longPollMode   = true
            // pollSec        = 10
            // isPolling      = false
            // nextPollIn     = 10
            // pollFailure    = false
            if longPollMode && !isPolling {
                nextPollIn = nextPollIn - 1
                
                if nextPollIn <= 0 {
                    
                    Task {
                        await pollMedia()
                    }
                    
                    nextPollIn = 10
                }
                
            }
            
        }

    }


    /*
    ** ********************************************************************************************
    */
    var title: String {
        #if os(iOS)
//        if selectMode.isActive || mediaSelection.isEmpty {
            return "\(section != "␀" ? section : " unbekannt")"
//        } else {
//            return "\(mediaSelection.count) Selected"
//        }
        #else
        return "\(section != "␀" ? section : " unbekannt")"
        #endif
    }

    /*
    ** ********************************************************************************************
    */
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
                    NSPredicate (format: "location contains[cd] %@", newValue),
                    NSPredicate (format: "fulltext contains[cd] %@", newValue)
            ])
        }

        return f
    }


    /*
    ** ********************************************************************************************
    */
    private func makeScannerView()-> some View {
        ScannerView(completion: { scanData in
            mediaProvider.importSet(scanData)
            self.showScannerSheet = false
        })
    }


    /*
    ** ********************************************************************************************
    */
    private func deleteMediaByOffsets(from section: SectionedFetchResults<String, Media>.Element, at offsets: IndexSet) {
        let objectIDs = offsets.map { section[$0].objectID }
        mediaProvider.deleteMedia(identifiedBy: objectIDs)
        mediaSelection.removeAll()
    }

    /*
    ** ********************************************************************************************
    */
    private func deleteMedia(for codes: Set<String>) async {
        do {
            let mediaToDelete = media.joined().filter { codes.contains($0.filename) }
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

    /*
    ** ********************************************************************************************
    */
    private func fetchMedia(complete: Bool = false) async {
        isLoading = true
        do {
            try await mediaProvider.fetchMedia(pollingFor: 0, complete: complete)
            lastUpdated = Date().timeIntervalSince1970
        } catch {
            self.error = error as? DscanError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        isLoading = false
    }

    /*
    ** ********************************************************************************************
    */
    private func pollMedia() async {
        isPolling = true
        let p = mediaProvider.suggestPoll()
        do {
            try await mediaProvider.fetchMedia(pollingFor: p)
            lastUpdated = Date().timeIntervalSince1970
        } catch {
            self.error = error as? DscanError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        isPolling = false
    }


    /*
    ** ********************************************************************************************
    */
    private func processAllMedia() async {
        mp.processAllImages()
//        await fetchMedia()
    }
    

    /*
    ** ********************************************************************************************
    */
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
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            SelectButton(mode: $selectMode) {
                let A = media.first(where: { $0.id == section })
                if selectMode.isActive && A != nil {
                    mediaSelection = Set(A!.map { $0.filename })
                } else {
                    mediaSelection = []
                }
            }
            .disabled(editMode != .active)
            .opacity (editMode != .active ? 0 : 1)

            EditButton(editMode: $editMode) {
                mediaSelection.removeAll()
                editMode = .inactive
                selectMode = .inactive
            }

        }
        
        ToolbarItemGroup(placement: .bottomBar) {
            let n = media.first(where: { $0.id == section })?.count ?? 0
            
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
                itemCount: n,
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: 0,
                selectedCount: mediaSelection.count
            )

            Spacer()

            DeleteButton {
                Task {
                    await deleteMedia(for: mediaSelection)
                    selectMode = .inactive
                }
            }
            .disabled(isLoading || mediaSelection.isEmpty)
            .opacity (editMode == .active ? 1 : 0)
            
            AnalyzeButton {
                Task {
                    await processAllMedia()
                }
            }
            
            Text("new: \(newMedia.count)")
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
                sectionCount: 0,
                itemCount: n
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

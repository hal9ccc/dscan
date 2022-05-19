//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI


struct MediaList: View {
//    let sortId:  Int

    let section:         MediaSection
    let startWithKey:    String

    @State private var key: String = ""

    @EnvironmentObject var app: AppState

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

//    @AppStorage("searchTerm")
    @State private var mediaSearchTerm = ""
    
    @State private var isLoading       = false
    @State private var lastSortChange: Date = Date()

    let polltimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var longPollMode   = false
    @State private var maxCid         = -1   // last known Change-ID
    @State private var pollSec        = 10
    @State private var isPolling      = false
    @State private var nextPollIn     = 10
    @State private var pollFailure    = false

    @State private var showScannerSheet = false
    @State private var texts:[ScanDataOrig] = []

    @State
    private var lastUpdatedMedia: Date = .now
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }


    /*
    ** ********************************************************************************************
    */
    var body: some View {

        let request = media
        request.sectionIdentifier = section.section
        request.sortDescriptors   = section.descriptors
//        print("MediaList \(section.name) -> \(key)")
        
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
        
     
    return HStack {
        
        if idiom == .pad && section != MediaSection.all {
                        
            ScrollView {
                            
                ForEach(media) { mediaSection in
                    VStack {
                        
                        if self.key == mediaSection.id {
                            Button(action: { self.key = mediaSection.id } )
                            {
                                SectionRow(section:section, id: mediaSection.id, count: mediaSection.count)
                            }
                            .buttonStyle( .borderedProminent)
                        }
                        else {
                            Button(action: { self.key = mediaSection.id } )
                            {
                                SectionRow(section:section, id: mediaSection.id, count: mediaSection.count)
                            }
                            .buttonStyle( .bordered)
                        }
                    }
                }
            } // List
            .padding()
            .frame(width: 320)
        }

        List(selection: $mediaSelection) {
            
            if newMedia.count > 0 {
                AnalyzeButton(count: newMedia.count) {
                    app.processAllImages(completion: {} )
                }
                .listRowBackground(Color.clear)
            }
            
            ForEach(media) { sect in

                if sect.id == key || section == MediaSection.all {

                    ForEach(sect, id: \.filename) { media in
                        if media.filename > "" {
                            NavigationLink(destination: MediaDetail(media: media)) {
                                MediaRow(media: media)
                            }.listRowBackground(Color.clear)
                        }
                    }
                    .onDelete { indexSet in
                        withAnimation { deleteMediaByOffsets (from: sect, at: indexSet) }
                    }
                }
            }
            }
        }
        .background(
            LinearGradient(
                stops: [SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0), SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .searchable(text: mediaSearchQuery)
        .listStyle(PlainListStyle())
        .navigationTitle (title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!mediaSelection.isEmpty)
        .toolbar (content: toolbarContent)

#if os(iOS)
        .environment(\.editMode, $editMode)
        .refreshable { await fetchMedia(complete: true) }
#else
        .frame(minWidth: 320)
#endif

        .alert(isPresented: $hasError, error: error) { }
        .sheet(isPresented: $showScannerSheet, content: {
            self.makeScannerView()
        })
        .onAppear() {
            if key == "" { key = startWithKey }
            let n = media.first(where: { $0.id == key })?.count ?? 0
            if n == 0 {
                key = media.count > 0 ? media[0].id : ""
            }

            if idiom == .pad {
                publishInfo()
            }
        }
        .onReceive(polltimer) { input in
            if idiom == .pad {
                publishInfo()
            }
        }

    }

    /*
    ** ********************************************************************************************
    */
    func publishInfo() {
//        print(media.first(where: { $0.id == key })?.count ?? 0)
        let _ = app.publishInfo (
            ts:         lastUpdatedMedia,
            sect:       section,
            key:        key,
            sections:   media.count,
            items:      media.joined().count,
            showing:    media.first(where: { $0.id == key })?.count ?? 0,
            selected:   mediaSelection.count,
            loading:    isLoading
        )
    }

    /*
    ** ********************************************************************************************
    */
    var title: String {
        #if os(iOS)
//            publishInfo()
//        if selectMode.isActive || mediaSelection.isEmpty {
            return "\(key != "␀" ? key : " unbekannt")"
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

//            print ("key:\(key)")
//            if key == "" { key = startWithKey }
//            let n = media.first(where: { $0.id == key })?.count ?? 0
//            print ("n:\(n)")
//            if n == 0 {
//                key = media.count > 0 ? media[0].id : ""
//            }
//            print ("media.count:\(media.count)")
            
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
//            lastUpdatedMedia = Date().timeIntervalSince1970
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
//            lastUpdatedMedia = Date().timeIntervalSince1970
        } catch {
            self.error = error as? DscanError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        isPolling = false
    }


    /*
    ** ********************************************************************************************
    */
    private func processAllMedia()  {
        app.processAllImages( completion: { fetchMediaTask() } )
    }
    

    /*
    ** ********************************************************************************************
    */
    private func fetchMediaTask()  {
        Task {
            print("FÄTSCHING!!!!!!!!!!!!!!!!!!!!!!!!")
            await fetchMedia()
        }
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

        ToolbarItemGroup(placement: .navigationBarLeading) {
            
            DeleteButton {
                Task {
                    await deleteMedia(for: mediaSelection)
                    selectMode = .inactive
                }
            }
            .disabled(isLoading || mediaSelection.isEmpty)
            .opacity (mediaSelection.isEmpty ? 0 : 1)
            .if (isLoading || mediaSelection.isEmpty) { v in v.hidden() }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            SelectButton(mode: $selectMode) {
                let A = media.first(where: { $0.id == key })
                if selectMode.isActive && A != nil {
                    mediaSelection = Set(A!.map { $0.filename })
                } else {
                    mediaSelection = []
                }
            }
            .if(editMode != .active) { v in v.hidden() }

            EditButton(editMode: $editMode) {
                mediaSelection.removeAll()
                editMode = .inactive
                selectMode = .inactive
            }
            
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

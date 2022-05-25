//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI


struct MediaList: View {

    let section:         MediaSection
    let startWithKey:    String

    @State private var key: String = ""

    @EnvironmentObject var app: DScanApp

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

            List {

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
                    .listRowBackground(Color.clear)
                }
            } // List
            .padding()
            .frame(width: 320)
        }



        List(selection: $mediaSelection) {

            AnalyzeButtonAuto()

            LastUpdatedView()

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
            stops: [
                SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0),
                SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .searchable(text: mediaSearchQuery)
    .disableAutocorrection(true)
    .listStyle(PlainListStyle())
    .navigationTitle (title)
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(!mediaSelection.isEmpty)
    .toolbar (content: toolbarContent)

#if os(iOS)
        .environment(\.editMode, $editMode)
        .refreshable { app.fetchMedia(complete: true, _force: true) }
#else
        .frame(minWidth: 320)
#endif

        .alert(isPresented: $hasError, error: error) { }
        .sheet(isPresented: $showScannerSheet, content: {
            self.makeScannerView()
        })
        .onAppear() {

            let request = media
            request.sectionIdentifier = section.section
            request.sortDescriptors   = section.descriptors



            if key == "" { key = startWithKey }
            let n = media.first(where: { $0.id == key })?.count ?? 0
            if n == 0 {
                key = media.count > 0 ? media[0].id : ""
            }

//            if idiom == .pad {
                publishInfo()
//            }
        }
//        .onReceive(polltimer) { inpu  t in
//            publishInfo()
//        }

    }

    /*
    ** ********************************************************************************************
    */
    func publishInfo() {
        //print(media.first(where: { $0.id == key })?.count ?? 0)
        app.publishInfo (
            sect:       section,
            key:        key,
            sections:   media.count,
            items:      media.joined().count,
            showing:    media.first(where: { $0.id == key })?.count ?? 0,
            selected:   mediaSelection.count
        )
    }

    /*
    ** ********************************************************************************************
    */
    var title: String {
        #if os(iOS)
        return "\(key != "␀" ? "\(key)" : " unbekannt")"
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
            .disabled(mediaSelection.isEmpty)
            .opacity (mediaSelection.isEmpty ? 0 : 1)
            .if (mediaSelection.isEmpty) { v in v.hidden() }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if editMode == .active {
                SelectButton(mode: $selectMode) {
                    let A = media.first(where: { $0.id == key })
                    if selectMode.isActive && A != nil {
                        mediaSelection = Set(A!.map { $0.filename })
                    } else {
                        mediaSelection = []
                    }
                }
            }
//            . { v in v.hidden() }

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
                isLoading: app.isLoading,
                lastUpdated: app.lastChange,
                sectionCount: 0,
                itemCount: n
            )
        }

        ToolbarItemGroup(placement: .navigation) {
            HStack {

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

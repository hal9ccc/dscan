//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

    
struct MediaView: View {
    
    var mediaProvider:  MediaProvider  = .shared

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
    
    @State private var selectedMediaSort: MediaSort = MediaSort.default
    @State private var mediaSearchTerm = ""
    @State private var isLoading = false

    @AppStorage("lastUpdatedMedia")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970


    
    var body: some View {

        NavigationView {
           
            List(selection: $mediaSelection) {
                
                ForEach(media) { section in
                    
                    Section(
                        header: SectionHeader(name: "\(section.id)", pill:"\(section.count)")) {
                            //header: Text("\(section.id) [\(section.count)]")) {
                            
                            ForEach(section, id: \.id) { media in
                                NavigationLink(destination: MediaDetail(media: media)) {
                                    MediaRow(media: media)
                                }
                            }
                            .onDelete { indexSet in
                                withAnimation {
                                    deleteMediaByOffsets (
                                        from: section,
                                        at:   indexSet
                                    )
                                }
                            }
                        }
                        .headerProminence(.increased)
                }
            }
            .listStyle(SidebarListStyle())
            .searchable(text: mediaSearchQuery)
            .navigationTitle(title)
            .toolbar(content: toolbarContent)
    #if os(iOS)
            .environment(\.editMode, $editMode)
            .refreshable {
                await fetchMedia()
            }
    #else
            .frame(minWidth: 320)
    #endif
            
            EmptyView()
        }
    }
    
    var title: String {
        #if os(iOS)
        if selectMode.isActive || mediaSelection.isEmpty {
            return "Documents"
        } else {
            return "\(mediaSelection.count) Selected"
        }
        #else
        return "Documents"
        #endif
    }

    var mediaSearchQuery: Binding<String> {
      Binding {
        mediaSearchTerm
      } set: { newValue in
        mediaSearchTerm = newValue
        
        guard !newValue.isEmpty else {
//          media.nsPredicate = nil
          return
        }

        media.nsPredicate = NSPredicate (
            format: "code contains[cd] %@",
            newValue
        )
      }
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
        ToolbarItem(placement: .primaryAction) {
            MediaSortSelection (selectedSortItem: $selectedMediaSort, sorts: MediaSort.sorts)
            onChange(of: selectedMediaSort) { _ in
                let config = media
                config.sortDescriptors   = selectedMediaSort.descriptors
                config.sectionIdentifier = selectedMediaSort.section
            }
        }

        ToolbarItem(placement: .navigationBarLeading) {
            if editMode == .active {
                SelectButton(mode: $selectMode) {
                    if selectMode.isActive {
                        mediaSelection = Set(media.joined().map { $0.id })
                    } else {
                        mediaSelection = []
                    }
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }
    #else
    @ToolbarContentBuilder
    private func toolbarContent_macOS() -> some ToolbarContent {

        ToolbarItemGroup(placement: .status) {
            SortSelectionView (selectedSortItem: $selectedSort, sorts: MediaSort.sorts)
            onChange(of: selectedSort) { _ in
                let config = media
                config.sortDescriptors = selectedSort.descriptors
                config.sectionIdentifier = selectedSort.section
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

//
//  QuakeView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct QuakeView: View {

    var quakesProvider: QuakesProvider = .shared

    @SectionedFetchRequest (
        sectionIdentifier: QuakeSort.default.section,
        sortDescriptors: QuakeSort.default.descriptors,
        animation: .default
    )
    private var quakes: SectionedFetchResults<String, Quake>
    
    @State private var selectedQuakeSort: QuakeSort = QuakeSort.default
    @State private var quakeSearchTerm = ""
    
    @State private var isLoading = false

    @AppStorage("lastUpdatedQuakes")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970

    @State private var quakeSelection: Set<String> = []

    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    @State private var selectMode: SelectMode = .inactive
    #endif

    @State private var error: DscanError?
    @State private var hasError = false

    
    var body: some View {
        
        NavigationView {
            
            List(selection: $quakeSelection) {
                
                ForEach(quakes) { section in
                    
                    Section(
                        header: SectionHeader(name: "\(section.id)", pill:"\(section.count)")) {
                            //header: Text("\(section.id) [\(section.count)]")) {
                            
                            ForEach(section, id: \.code) { quake in
                                NavigationLink(destination: QuakeDetail(quake: quake)) {
                                    QuakeRow(quake: quake)
                                }
                            }
                            .onDelete { indexSet in
                                withAnimation {
                                    deleteQuakesByOffsets (
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
            .searchable(text: quakeSearchQuery)
            .navigationTitle(title)
            .toolbar(content: toolbarContent)
#if os(iOS)
            .environment(\.editMode, $editMode)
            .refreshable {
                await fetchQuakes()
            }
#else
            .frame(minWidth: 320)
#endif
            
            EmptyView()
        }
        .alert(isPresented: $hasError, error: error) { }
    }
    

    var title: String {
        #if os(iOS)
        if selectMode.isActive || quakeSelection.isEmpty {
            return "Earthquakes"
        } else {
            return "\(quakeSelection.count) Selected"
        }
        #else
        return "Earthquakes"
        #endif
    }

    var quakeSearchQuery: Binding<String> {
        Binding {
            quakeSearchTerm
        } set: { newValue in
        
            quakeSearchTerm = newValue
        
            guard !newValue.isEmpty else {
                quakes.nsPredicate = nil
            return
        }

        quakes.nsPredicate = NSPredicate (
            format: "place contains[cd] %@",
            newValue
        )
      }
    }
    

    private func deleteQuakesByOffsets(from section: SectionedFetchResults<String, Quake>.Element, at offsets: IndexSet) {
        let objectIDs = offsets.map { section[$0].objectID }
        quakesProvider.deleteQuakes(identifiedBy: objectIDs)
        quakeSelection.removeAll()
    }

    private func deleteQuakes(for codes: Set<String>) async {
        do {
            let quakesToDelete = quakes.joined().filter { codes.contains($0.code) }
            //print (section)
            print ("deleting \(quakesToDelete.count) quakes...")
            try await quakesProvider.deleteQuakes(quakesToDelete)
        } catch {
            self.error = error as? DscanError ?? .unexpectedError(error: error)
            self.hasError = true
        }

        quakeSelection.removeAll()
        #if os(iOS)
        editMode = .inactive
        #endif
    }


    private func fetchQuakes() async {
        isLoading = true
        do {
            try await quakesProvider.fetchQuakes()
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
            QuakeSortSelection (selectedSortItem: $selectedQuakeSort, sorts: QuakeSort.sorts)
            onChange(of: selectedQuakeSort) { _ in
                let config = quakes
                config.sortDescriptors   = selectedQuakeSort.descriptors
                config.sectionIdentifier = selectedQuakeSort.section
            }
        }

        ToolbarItem(placement: .navigationBarLeading) {
            if editMode == .active {
                SelectButton(mode: $selectMode) {
                    if selectMode.isActive {
                        quakeSelection = Set(quakes.joined().map { $0.code })
                    } else {
                        quakeSelection = []
                    }
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton(editMode: $editMode) {
                quakeSelection.removeAll()
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
                        await fetchQuakes()
                    }
                }
                .disabled(isLoading || editMode == .active)
            }

            Spacer()

            ToolbarStatus(
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: quakes.count,
                itemCount: quakes.joined().count
            )

            Spacer()

            if editMode == .active {
                DeleteButton {
                    Task {
                        await deleteQuakes(for: quakeSelection)
                        selectMode = .inactive
                    }
                }
                .disabled(isLoading || quakeSelection.isEmpty)
            }
        }
    }
    #else
    @ToolbarContentBuilder
    private func toolbarContent_macOS() -> some ToolbarContent {

        ToolbarItemGroup(placement: .status) {
            SortSelectionView (selectedSortItem: $selectedSort, sorts: QuakeSort.sorts)
            onChange(of: selectedSort) { _ in
                let config = quakes
                config.sortDescriptors = selectedSort.descriptors
                config.sectionIdentifier = selectedSort.section
            }

            ToolbarStatus(
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: quakes.count,
                itemCount: quakes.joined().count
            )
        }

        ToolbarItemGroup(placement: .navigation) {
            HStack {
                ProgressView()
             //       .disabled(!isLoading)

                RefreshButton {
                    Task {
                        await fetchQuakes()
                    }
                }
                .hidden(isLoading)
                
                Spacer()
                
                DeleteButton {
                    Task {
                        await deleteQuakes(for: selection)
                    }
                }
                .disabled(isLoading || selection.isEmpty)
            }
        }
    }
    #endif

    
    
}

struct QuakeView_Previews: PreviewProvider {
    static let quakesProvider = QuakesProvider.preview

    static var previews: some View {
        QuakeView(quakesProvider: quakesProvider)
            .environment(\.managedObjectContext,
                          quakesProvider.container.viewContext)

    }
}

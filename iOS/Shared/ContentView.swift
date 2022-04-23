/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The views of the app, which display details of the fetched earthquake data.
*/

import SwiftUI
import CoreData
import OSLog

struct ContentView: View {
    var quakesProvider: QuakesProvider = .shared

    @AppStorage("lastUpdated")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970

    @SectionedFetchRequest (
        sectionIdentifier: QuakeSort.default.section,
        sortDescriptors: QuakeSort.default.descriptors,
        animation: .default
    )
    private var quakes: SectionedFetchResults<String, Quake>
    
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    @State private var selectMode: SelectMode = .inactive
    #endif

    @State private var selectedSort: QuakeSort = QuakeSort.default
    @State private var searchTerm = ""
    
    @State private var selection: Set<String> = []
    @State private var isLoading = false
    @State private var error: QuakeError?
    @State private var hasError = false
    
    @State private var searchText = ""
    
    let logger = Logger(subsystem: "com.example.apple-samplecode.Earthquakes", category: "view")

    var searchQuery: Binding<String> {
      Binding {
        searchTerm
      } set: { newValue in
        searchTerm = newValue
        
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
    

    var body: some View {
        tabView
            .alert(isPresented: $hasError, error: error) { }
    }


    var tabView: some View {
        TabView {
            quakeView
                .tabItem {
                    Label("Quakes", systemImage: "list.dash")
                }
            mediaView
                .tabItem {
                    Label("Media", systemImage: "square.and.pencil")
                }
        }
        
    }
    
    var mediaView: some View {
        Text("Media")
    }


    var quakeView: some View {
        //print(quakes)

        NavigationView {

            List(selection: $selection) {
                
                ForEach(quakes) { section in

                    Section(header: Text("\(section.id) [\(section.count)]")) {
                        
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
                }
            }
            .searchable(text: searchQuery)
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

    
}

// MARK: Core Data

extension ContentView {
    var title: String {
        #if os(iOS)
        if selectMode.isActive || selection.isEmpty {
            return "Earthquakes"
        } else {
            return "\(selection.count) Selected"
        }
        #else
        return "Earthquakes"
        #endif
    }

    private func deleteQuakesByOffsets(from section: SectionedFetchResults<String, Quake>.Element, at offsets: IndexSet) {
        let objectIDs = offsets.map { section[$0].objectID }
        print (objectIDs)
        quakesProvider.deleteQuakes(identifiedBy: objectIDs)
        selection.removeAll()
    }

    private func deleteQuakes(for codes: Set<String>) async {
        do {
            let quakesToDelete = quakes.joined().filter { codes.contains($0.code) }
            //print (section)
            print ("deleting \(quakesToDelete.count) quakes...")
            try await quakesProvider.deleteQuakes(quakesToDelete)
        } catch {
            self.error = error as? QuakeError ?? .unexpectedError(error: error)
            self.hasError = true
        }

        selection.removeAll()
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
            self.error = error as? QuakeError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        isLoading = false
    }
}

// MARK: Toolbar Content

extension ContentView {
    
   
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
            SortSelectionView (selectedSortItem: $selectedSort, sorts: QuakeSort.sorts)
            onChange(of: selectedSort) { _ in
                let config = quakes
                config.sortDescriptors = selectedSort.descriptors
                config.sectionIdentifier = selectedSort.section
            }
        }

        ToolbarItem(placement: .navigationBarLeading) {
            if editMode == .active {
                SelectButton(mode: $selectMode) {
                    if selectMode.isActive {
                        selection = Set(quakes.joined().map { $0.code })
                    } else {
                        selection = []
                    }
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton(editMode: $editMode) {
                selection.removeAll()
                editMode = .inactive
                selectMode = .inactive
            }
        }

        ToolbarItemGroup(placement: .bottomBar) {
            RefreshButton {
                Task {
                    await fetchQuakes()
                }
            }
            .disabled(isLoading || editMode == .active)

            Spacer()
            ToolbarStatus(
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                sectionCount: quakes.count,
                quakesCount: quakes.joined().count
            )
            Spacer()

            if editMode == .active {
                DeleteButton {
                    Task {
                        await deleteQuakes(for: selection)
                        selectMode = .inactive
                    }
                }
                .disabled(isLoading || selection.isEmpty)
            }
        }
    }
    #else
    @ToolbarContentBuilder
    private func toolbarContent_macOS() -> some ToolbarContent {
        ToolbarItemGroup(placement: .status) {
            ToolbarStatus(
                isLoading: isLoading,
                lastUpdated: lastUpdated,
                quakesCount: quakes.count
            )
        }

        ToolbarItemGroup(placement: .navigation) {
            RefreshButton {
                Task {
                    await fetchQuakes()
                }
            }
            .disabled(isLoading)
            Spacer()
            DeleteButton {
                Task {
                    await deleteQuakes(for: selection)
                }
            }
            .disabled(isLoading || selection.isEmpty)
        }
    }
    #endif
}

struct ContentView_Previews: PreviewProvider {
    static let quakesProvider = QuakesProvider.preview
    static var previews: some View {
        ContentView(quakesProvider: quakesProvider)
            .environment(\.managedObjectContext,
                          quakesProvider.container.viewContext)
    }
}

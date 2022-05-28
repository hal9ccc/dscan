//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

    
struct MediaSectionList: View {
    
    var section:  MediaSection    = .default


    @EnvironmentObject var app: DScanApp

    let mediaProvider:      MediaProvider   = .shared

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
    
    
    //    @State private var selectedMediaSort:  MediaSection    = .default

    @State private var mediaSelection: Set<String> = []

    @State private var error: DscanError?
    @State private var hasError = false
    
//    @State private var selectedMediaSort: MediaSection = MediaSection.default
//    @AppStorage("searchTerm")
    @State private var mediaSearchTerm = ""
    @State private var isLoading = false
    @State private var lastSortChange: Date = Date()
    
    @State private var showScannerSheet = false
    @State private var texts:[ScanDataOrig] = []
    

//    @State
    @AppStorage("lastSelectedSort")
    private var lastSelectedSort = MediaSection.default.id

    @AppStorage("lastSelectedSection")
    private var lastSelectedSection = ""

//    @AppStorage("lastUpdatedMedia")
    @State
    private var lastUpdated: Date = Date.now
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    
    var body: some View {

        //lastSelectedSort = section.id
        
        let request = media
        request.sectionIdentifier = MediaSection.sorts[section.id].section
        request.sortDescriptors   = MediaSection.sorts[section.id].descriptors
//        print("MediaSectionList \(MediaSection.sorts[section.id].name) -> \(lastSelectedSection)")

        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyyMMdd"

        let dayFormatter = DateFormatter()
        dayFormatter.dateStyle = .full
        dayFormatter.timeStyle = .none
        dayFormatter.locale = .init(identifier: "de_DE")

        return VStack {

            if idiom != .pad  {
                AnalyzeButtonAuto()
            }
            
            List() {
                ForEach(media) { mediaSection in
                    
                    NavigationLink(destination: MediaList(section: section, startWithKey:mediaSection.id, showSections: false)) {
                        if section == MediaSection.day {
                            SectionHeader (
                                name: dayFormatter.string(from: dateParser.date(from:mediaSection.id) ?? Date.now),
    //                            name: mediaSection.id,
                                pill:mediaSection.count
                            )
                        }
                        else {
                            SectionHeader(name: "\(mediaSection.id != "␀" ? mediaSection.id : " unbekannt ")", pill:mediaSection.count)
                        }
                    }.listRowBackground(Color.clear)
                }
                
                
                LastUpdatedView()
            } // List
        }
        .listStyle(PlainListStyle())
        .searchable(text: mediaSearchQuery)
        .disableAutocorrection(true)

        #if os(iOS)
        .refreshable { app.fetchMedia(complete: true) }
        #else
        .frame(minWidth: 320)
        #endif
        .background(
            LinearGradient(
                stops: [SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0),        SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear() { publishInfo() }
        .navigationTitle (title)
        .navigationBarTitleDisplayMode(.automatic)
        .alert(isPresented: $hasError, error: error) { }

        
    }
    
    var title: String {
        return section.name
    }

    /*
    ** ********************************************************************************************
    */
    func publishInfo() {
        app.publishInfo (
            sections:   media.count,
            items:      media.joined().count,
            selected:   mediaSelection.count,
            loading:    isLoading
        )
    }

    /*
    ** ********************************************************************************************
    */
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
                NSPredicate (format: "location contains[cd] %@", newValue),
                NSPredicate (format: "fulltext contains[cd] %@", newValue)
        ])
      }
    }

    
    private func makeScannerView()-> some View {
        ScannerView(completion: { scanData in
            mediaProvider.importSet(scanData)
            self.showScannerSheet = false
        })
    }
    

}

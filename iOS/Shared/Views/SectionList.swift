//
//  MediaView.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

    
struct SectionList: View {
    
    @State private var selectedMediaSort: MediaSection = MediaSection.default
    
//    @State
    @AppStorage("lastSelectedSection")
    private var lastSelectedSection = MediaSection.default.id

    @EnvironmentObject var mp: MediaProcessor
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    var mediaProvider:      MediaProvider   = .shared
    
//    @FetchRequest(
//        entity:             Media.entity(),
//        sortDescriptors:    [NSSortDescriptor(key: "id", ascending: false)],
//        predicate:          NSPredicate(format: "imageData != nil")
//     ) var newMedia: FetchedResults<Media>
    
    var body: some View {

        print("hor \(String(describing: horizontalSizeClass))")
        print("ver \(String(describing: verticalSizeClass))")

        
        return List() {
//
//            if newMedia.count > 0 {
//                AnalyzeButton(count: newMedia.count) {
//                    Task {
//                        await processAllMedia()
//                    }
//                }
//            }
            
            ForEach(MediaSection.sorts) { sort in
                

                if idiom == .pad {
                    NavigationLink(destination: MediaList(section: sort, startWithKey: "")) {
                        SectionHeader(name: "\(sort.name)", icon:sort.icon)
                    }
                    .padding( .bottom, sort == MediaSection.all ? 10 : 0)
                }
                else {
                    NavigationLink(destination: MediaSectionList(section: sort)) {
                        SectionHeader(name: "\(sort.name)", icon:sort.icon)
                    }
                    .padding( sort == MediaSection.all ? 1 : 0)
                }

            }
            
            NavigationLink(destination: SettingsView()) {
                SectionHeader(name: "Settings", icon:"gear")
            }
            .padding(.top)
            
        } // List
        .listStyle(SidebarListStyle())
        .background(
            LinearGradient(
                stops: [SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0),        SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle ("dScan")
        .navigationBarTitleDisplayMode(.inline)

        #if os(iOS)

        #else
                .frame(minWidth: 320)
        #endif
        

    }

    /*
    ** ********************************************************************************************
    */
    private func processAllMedia() async {
        mp.processAllImages()
//        await fetchMedia()
    }
    


}

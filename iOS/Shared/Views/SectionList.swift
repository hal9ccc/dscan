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
    
    var body: some View {

        List() {
            
            ForEach(MediaSection.sorts) { sort in
                
                NavigationLink(destination: MediaSectionList(section: sort)) {
                    SectionHeader(name: "\(sort.name)", icon:sort.icon)
                }
            }
            
             Spacer()
            
            NavigationLink(destination: SettingsView()) {
                SectionHeader(name: "Settings", icon:"gear")
            }
            
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
        
        Spacer()


    }
//        return MediaList(sortId: selectedMediaSort.id, section: lastSelectedSection)





}

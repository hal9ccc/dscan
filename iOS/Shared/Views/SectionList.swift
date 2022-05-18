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


    var body: some View {

        return VStack {

            AnalyzeButtonAuto()

            List() {
                
                ForEach(MediaSection.sorts) { sort in
                    
                    VStack {
                        if idiom == .pad {
                            NavigationLink(destination: MediaList(section: sort, startWithKey: "")) {
                                SectionHeader(name: "\(sort.name)", icon:sort.icon)
                            }
                        }
                        else if sort == MediaSection.all {
                            NavigationLink(destination: MediaList(section: sort, startWithKey: "")) {
                                SectionHeader(name: "\(sort.name)", icon:sort.icon)
                            }
                        }
                        else {
                            NavigationLink(destination: MediaSectionList(section: sort)) {
                                SectionHeader(name: "\(sort.name)", icon:sort.icon)
                            }
                        }
                        
                        if sort == MediaSection.all {
                            Spacer()
                            Spacer()
                        }

                    }
                   
                }

                VStack {
                    Spacer()
                    Spacer()

                    NavigationLink(destination: SettingsView()) {
                        SectionHeader(name: "Settings", icon:"gear")
                    }
                }
            } // List

        }
        

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




}

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

    @EnvironmentObject var mp: DScanApp
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }


    var body: some View {

        return VStack {

            AnalyzeButtonAuto()

            List() {

                NavigationLink(destination: MediaList(section: MediaSection.all, startWithKey: "")) {
                    SectionHeader(name: "\( MediaSection.all.name)", icon: MediaSection.all.icon)
                }

                Divider()
                
                ForEach(MediaSection.sorts.dropFirst()) { sort in
                    
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
                        
                    }
                   
                }

                Divider()

                NavigationLink(destination: SettingsView()) {
                    SectionHeader(name: "Settings", icon:"gear")
                }
                
                Spacer()
                
                LastUpdatedView()

            } // List

        }
        

        .listStyle(SidebarListStyle())
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
        .navigationTitle ("dScan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() { publishInfo() }

        #if os(iOS)

        #else
                .frame(minWidth: 320)
        #endif
        

    }


    /*
    ** ********************************************************************************************
    */
    func publishInfo() {
        let _ = mp.publishInfo (
            sections:   0
        )
    }

}

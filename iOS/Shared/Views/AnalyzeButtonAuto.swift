//
//  AnalyzeButtonAuto.swift
//  dscan
//
//  Created by Matthias Schulze on 18.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct AnalyzeButtonAuto: View {
    
    @EnvironmentObject var mp: AppState
    
    @FetchRequest(
        entity: Media.entity(),
        sortDescriptors:    [NSSortDescriptor(key: "id", ascending: false)],
        predicate:          NSPredicate(format: "imageData != nil")
     ) var newMedia: FetchedResults<Media>

    @State private var mediaSelection: Set<String> = []

    var body: some View {
        AnalyzeButton(count: newMedia.count) {
            mp.processAllImages(completion: {} )
        }
        .listRowBackground(Color.clear)
        .if(newMedia.count == 0) { v in v.hidden() }
    }

}

struct AnalyzeButtonAuto_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeButtonAuto()
    }
}

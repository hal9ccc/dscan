//
//  SortMenu.swift
//  Earthquakes
//
//  Created by Matthias Schulze on 14.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct MediaSortSelection: View {

    @Binding var selectedSortItem: MediaSection

    let sorts: [MediaSection]
    
    var body: some View {
        Menu {
          Picker("Sort By", selection: $selectedSortItem) {
            ForEach(sorts, id: \.self) { sort in
              Text("\(sort.name)")
            }
          }
        } label: {
          Label(
            "Sort",
            systemImage: "line.horizontal.3.decrease.circle")
        }
        .pickerStyle(.inline)
    }
}


struct MediaSortSelection_Previews: PreviewProvider {
    @State static var sort = MediaSection.default
    
    static var previews: some View {
        MediaSortSelection (
            selectedSortItem: $sort,
            sorts: MediaSection.sorts
        )
    }
}

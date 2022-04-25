//
//  QuakeSortSelection.swift
//  dscan
//
//  Created by Matthias Schulze on 25.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct QuakeSortSelection: View {

    @Binding var selectedSortItem: QuakeSort

    let sorts: [QuakeSort]
    
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


struct QuakeSortSelection_Previews: PreviewProvider {
    @State static var sort = QuakeSort.default
    
    static var previews: some View {
        QuakeSortSelection (
            selectedSortItem: $sort,
            sorts: QuakeSort.sorts
        )
    }
}

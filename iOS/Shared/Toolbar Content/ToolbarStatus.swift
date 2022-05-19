/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The toolbar status view of the app.
*/

import Foundation
import SwiftUI

struct ToolbarStatus: View {
    var lastUpdated:   Date
    var section:       MediaSection
    var sectionKey:    String
    var itemCount:     Int
    var isLoading:     Bool
    var sectionCount:  Int
    var showingCount:  Int
    var selectedCount: Int

    @State var currentDate = Date()
    @State var lastUpdate_str = ""
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                .if (lastUpdated == Date.distantFuture) { v in v.hidden() }
            
            HStack {
                Spacer()

                Text ( (selectedCount > 0 ? "\(selectedCount) von " : "")
                     + (showingCount  > 0 && sectionKey > "" ? "\(showingCount) in \(section.name) '\(sectionKey)' " : "")
                     + (showingCount == 0 ? "in \(sectionCount) Kategorien " : "")
                     + (selectedCount > 0 ? "ausgewählt" : "")
                )

                Spacer()
            }
            .foregroundStyle(Color.secondary)

        }
        .font(.caption)
//        .onReceive(timer) { input in
//            currentDate = input
//            let lastUpdatedDate = Date(timeIntervalSince1970: lastUpdated)
//            lastUpdate_str = "\(lastUpdatedDate.formatted(.relative(presentation: .named)))"
//            //print("currentDate=\(currentDate)")
//            //print("lastUpdated=\(lastUpdated)")
//        }
    }
}

struct ToolbarStatus_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarStatus (
            lastUpdated:   Date.distantPast,
            section:       MediaSection.default,
            sectionKey:    "Hallo",
            itemCount:     234,
            isLoading:     true,
            sectionCount:  5,
            showingCount:  77,
            selectedCount: 2
        )

    }
}

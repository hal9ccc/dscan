/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The toolbar status view of the app.
*/

import Foundation
import SwiftUI

struct ToolbarStatus: View {
    var itemCount: Int
    var isLoading: Bool
    var lastUpdated: TimeInterval
    var sectionCount: Int
    var selectedCount: Int

    @State var currentDate = Date()
    @State var lastUpdate_str = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if isLoading {
                Text("Updating...")
            }
            else if lastUpdated == Date.distantFuture.timeIntervalSince1970 {
                Spacer()
            }
            else {
                Text("Updated \(lastUpdate_str)")
            }
            Text((selectedCount > 0 ? "\(selectedCount) of " : "")
                 + "\(itemCount) documents"
                 + (sectionCount > 0 ? " in \(sectionCount) sections" : "")
                 + (selectedCount > 0 ? " selected" : ""))
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
        ToolbarStatus(
            itemCount: 10_000,
            isLoading: true,
            lastUpdated: Date.distantPast.timeIntervalSince1970,
            sectionCount: 5,
            selectedCount: 88
        )

        ToolbarStatus(
            itemCount: 10_000,
            isLoading: false,
            lastUpdated: Date.distantFuture.timeIntervalSince1970,
            sectionCount: 5,
            selectedCount: 0
        )

        ToolbarStatus(
            itemCount: 10_000,
            isLoading: false,
            lastUpdated: Date.now.timeIntervalSince1970,
            sectionCount: 5,
            selectedCount: 777
        )

        ToolbarStatus(
            itemCount: 10_000,
            isLoading: false,
            lastUpdated: Date.distantPast.timeIntervalSince1970,
            sectionCount: 5,
            selectedCount: 88
        )
    }
}

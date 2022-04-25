/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The toolbar status view of the app.
*/

import Foundation
import SwiftUI

struct ToolbarStatus: View {
    var isLoading: Bool
    var lastUpdated: TimeInterval
    var sectionCount: Int
    var itemCount: Int

    @State var currentDate = Date()
    @State var lastUpdate_str = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if lastUpdated == Date.distantFuture.timeIntervalSince1970 {
                Spacer()
            }
            else if isLoading {
                Text("Updating...")
            }
            else {
                Text("Updated \(lastUpdate_str)")
            }
            Text("\(itemCount) quakes in \(sectionCount) sections")
                .foregroundStyle(Color.secondary)

        }
        .font(.caption)
        .onReceive(timer) { input in
            currentDate = input
            let lastUpdatedDate = Date(timeIntervalSince1970: lastUpdated)
            lastUpdate_str = "\(lastUpdatedDate.formatted(.relative(presentation: .named)))"
            //print("currentDate=\(currentDate)")
            //print("lastUpdated=\(lastUpdated)")
        }
    }
}

struct ToolbarStatus_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarStatus(
            isLoading: true,
            lastUpdated: Date.distantPast.timeIntervalSince1970,
            sectionCount: 5,
            itemCount: 10_000
        )

        ToolbarStatus(
            isLoading: false,
            lastUpdated: Date.distantFuture.timeIntervalSince1970,
            sectionCount: 5,
            itemCount: 10_000
        )

        ToolbarStatus(
            isLoading: false,
            lastUpdated: Date.now.timeIntervalSince1970,
            sectionCount: 5,
            itemCount: 10_000
        )

        ToolbarStatus(
            isLoading: false,
            lastUpdated: Date.distantPast.timeIntervalSince1970,
            sectionCount: 5,
            itemCount: 10_000
        )
    }
}

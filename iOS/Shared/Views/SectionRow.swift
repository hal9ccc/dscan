//
//  SectionRow.swift
//  dscan
//
//  Created by Matthias Schulze on 18.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct SectionRow:  View {
    let section:    MediaSection
    let id:         String
    let count:      Int

    var body: some View {

        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyyMMdd"

        let dayFormatter = DateFormatter()
        dayFormatter.dateStyle = .full
        dayFormatter.timeStyle = .none
        dayFormatter.locale = Locale.current
       

        /*
        ** ********************************************************************************************
        */
        if section == MediaSection.day {
            return SectionHeader (
                name: dayFormatter.string(from: dateParser.date(from:id) ?? Date.now),
                pill: count
            )
        }
        else {
            return SectionHeader(name: "\(id != "␀" ? id : " unbekannt ")", pill:count)
        }


    }
}

struct SectionRow_Previews: PreviewProvider {
    static var previews: some View {
        SectionRow(section: MediaSection.default, id: "erereet", count: 4)
    }
}

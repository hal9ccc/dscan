//
//  AnalyzeButtonAuto.swift
//  dscan
//
//  Created by Matthias Schulze on 18.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct LastUpdatedView: View {
    
    @EnvironmentObject var app: DScanApp
    
    
    var body: some View {
        HStack (alignment: .center) {
            Spacer()

            Text("Last Updated \(app.lastUpdated.formatted(.relative(presentation: .named)))")
//            Text("\(app.lastUpdated.formatted()) - \(app.currentTime.formatted())")
                .foregroundColor(.secondary)
                .padding()
                
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}


struct LastUpdatedView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeButtonAuto()
    }
}

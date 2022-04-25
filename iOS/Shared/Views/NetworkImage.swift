//
//  NetworkImage.swift
//  dscan
//
//  Created by Matthias Schulze on 24.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct NetworkImage: View {

  let url: URL?
  let mode: String?

  var body: some View {
        if let url = url, let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .conditionalModifier(mode != nil && mode == "fill", {
                    $0.scaledToFill()
                }, {
                    $0.scaledToFit()
                })
                
        }
        else {
            Image(systemName: "square.dashed")
                .resizable()
                .conditionalModifier(mode != nil && mode == "fill", {
                    $0.scaledToFill()
                }, {
                    $0.scaledToFit()
                })

        }
  }
}

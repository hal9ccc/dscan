//
//  SettingsView.swift
//  dscan
//
//  Created by tizian on 05.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"
    
    @AppStorage("CacheSize")
    private var cachesize: Double = 50
    
    @State
    private var cachesizeOrig: Double = 0
    
    @AppStorage("CompressionQuality")
    private var comprQual: Double = 0.5
    
    
    var body: some View {
 
        Form {
            Section (header:Text("Server address")) {
                
                Text("Server URL")
                    .font(.headline)

                TextField ( "http://server.domain/ords/dscan", text: $serverurl )
                    .disableAutocorrection(true)
                    .font(.subheadline)
                
            }

            Section (
                header:Text("Image cache"),
                footer:Text("Änderung wird erst durch Neustart der App wirksam!")
                    .font(.caption)
                    .foregroundColor(Color.red)
                    .opacity(cachesizeOrig == cachesize ? 0 : 1)
            ) {
                Slider (
                    value: $cachesize,
                    in: 100 * 1024 * 1024...5000 * 1024 * 1024,
                    step: 100 * 1024 * 1024,
                    label: { Text("Cache Size") }
                )
                    
                Text("\((cachesize/(1024 * 1024)).formatted()) MB")
                    .font(.subheadline)
            }
                
            Section (
                header:Text("Image quality"),
                footer:Text("Compression level for image upload. Does not affect OCR or barcode detection performance")
            ) {
                Slider(value: $comprQual,
                     in: 0.1...1,
                     step: 0.1,
                     minimumValueLabel: Text("low"),
                     maximumValueLabel: Text("high"),
                     label: { Text("Image quality") }
                )
                
            }

        }
        .onAppear {
            cachesizeOrig = cachesize
        }
    }
}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

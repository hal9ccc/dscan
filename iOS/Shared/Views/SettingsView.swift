//
//  SettingsView.swift
//  dscan
//
//  Created by tizian on 05.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    init(){
            UITableView.appearance().backgroundColor = .clear
    }
    
    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"
    
    @State
    private var serverurlOrig = ""
    
    @AppStorage("CacheSize")
    private var cachesize: Double = 100 * 1024 * 1024
    
    @State
    private var cachesizeOrig: Double = 0
    
    @AppStorage("CompressionQuality")
    private var comprQual: Double = 0.5
    
    var body: some View {
        Form {
            Section (
                header:Text("Server address"),
                footer:Text("Änderung wird erst durch Neustart der App wirksam!")
                    .font(.caption)
                    .foregroundColor(Color.red)
                    .opacity(serverurlOrig == serverurl ? 0 : 1)
            ) {
                
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

            Section (
                header:Text("Approximate Number of images"),
                footer:Text("Actual number may vary, based on color or size of the Image")
            ) {
                Text("\(Int((cachesize/1024)/(comprQual * 1024)))")

            }
        }
        .onAppear {
            cachesizeOrig = cachesize
        }
        .onAppear {
            serverurlOrig = serverurl
        }
        .background(
            LinearGradient(
                stops: [SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0), SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 0.5), SwiftUI.Gradient.Stop(color: Color("Color-2"), location: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
            )
        )
        //colors in assets https://thehappyprogrammer.com/lineargradient-swiftui
    }
}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

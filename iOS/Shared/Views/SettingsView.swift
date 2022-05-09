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
 
        VStack {
            Text("Settings")
                .font(.title)
            Form{
                VStack(
                    alignment: .leading, spacing: 10
                    )
                {
                    Text("Server URL")
                        .font(.headline)
                    TextField(
                        "Server URL",
                        text: $serverurl
                    )
                        .disableAutocorrection(true)
                        .font(.subheadline)
                    Divider()
                    Text("Cache Size")
                        .font(.headline)
                    Slider(value: $cachesize,
                           in: 100 * 1024 * 1024...5000 * 1024 * 1024,
                           step: 100 * 1024 * 1024,
                           minimumValueLabel: Text("100MB"),
                           maximumValueLabel: Text("5000MB"),
                           label: {
                                Text("Cache Size")
                        }
                    )
                    Text("\((cachesize/(1024 * 1024)).formatted()) MB")
                        .font(.subheadline)
                    Text("Änderung wird erst durch Neustart der App wirksam!")
                        .font(.caption)
                        .foregroundColor(Color.red)
                        .opacity(cachesizeOrig == cachesize ? 0 : 1)
                    Divider()
                    Text("JPG Compression")
                        .font(.headline)
                    Slider(value: $comprQual,
                           in: 0.1...1,
                           step: 0.1,
                           minimumValueLabel: Text("0.1"),
                           maximumValueLabel: Text("1"),
                           label: {
                                Text("Compression Quality")
                        }
                    )
                    
                }
                .textFieldStyle(.roundedBorder)
                .padding()
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

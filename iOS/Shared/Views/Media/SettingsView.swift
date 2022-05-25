//
//  SettingsView.swift
//  dscan
//
//  Created by Tizian Frank on 05.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    
    init() {
            UITableView.appearance().backgroundColor = .clear
    }
    
    @EnvironmentObject var app: DScanApp
    
    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"
    
    @State
    private var serverurlOrig = ""
    
    @AppStorage("AutoUpdate")
    private var autoUpdate: Bool = true
    
    @AppStorage("AutoUpdateSeconds")
    private var autoUpdateSeconds: Double = 10
    
    @AppStorage("LongpollMode")
    private var longpollMode: Bool = true
    
    @AppStorage("LongpollSeconds")
    private var longpollSeconds: Double = 60
    
    
    @AppStorage("CacheSize")
    private var cachesize: Double = 100 * 1024 * 1024
    
    @State
    private var cachesizeOrig: Double = 0
    
    @AppStorage("CompressionQuality")
    private var comprQual: Double = 0.5
    
    @AppStorage("DataSyncHours")
    private var syncRange: Double = 48
    
    @State
    private var syncRange_str = ""

    @AppStorage ("BS_aztec")                   private var bs_aztec:                   Bool = true
    @AppStorage ("BS_code39")                  private var bs_code39:                  Bool = true
    @AppStorage ("BS_code39Checksum")          private var bs_code39Checksum:          Bool = true
    @AppStorage ("BS_code39FullASCII")         private var bs_code39FullASCII:         Bool = true
    @AppStorage ("BS_code39FullASCIIChecksum") private var bs_code39FullASCIIChecksum: Bool = true
    @AppStorage ("BS_code93")                  private var bs_code93:                  Bool = true
    @AppStorage ("BS_code93i")                 private var bs_code93i:                 Bool = true
    @AppStorage ("BS_code128")                 private var bs_code128:                 Bool = true
    @AppStorage ("BS_dataMatrix")              private var bs_dataMatrix:              Bool = true
    @AppStorage ("BS_ean8")                    private var bs_ean8:                    Bool = true
    @AppStorage ("BS_ean13")                   private var bs_ean13:                   Bool = true
    @AppStorage ("BS_i2of5")                   private var bs_i2of5:                   Bool = true
    @AppStorage ("BS_i2of5Checksum")           private var bs_i2of5Checksum:           Bool = true
    @AppStorage ("BS_itf14")                   private var bs_itf14:                   Bool = true
    @AppStorage ("BS_pdf417")                  private var bs_pdf417:                  Bool = true
    @AppStorage ("BS_qr")                      private var bs_qr:                      Bool = true
    @AppStorage ("BS_upce")                    private var bs_upce:                    Bool = true
    @AppStorage ("BS_codabar")                 private var bs_codabar:                 Bool = true
    @AppStorage ("BS_gs1DataBar")              private var bs_gs1DataBar:              Bool = true
    @AppStorage ("BS_gs1DataBarExpanded")      private var bs_gs1DataBarExpanded:      Bool = true
    @AppStorage ("BS_gs1DataBarLimited")       private var bs_gs1DataBarLimited:       Bool = true
    @AppStorage ("BS_microPDF417")             private var bs_microPDF417:             Bool = true
    @AppStorage ("BS_microQR")                 private var bs_microQR:                 Bool = true

    
    let currentDate = Date()
    
    var body: some View {
        
        Form {
            
            Section (
                header:Text("Server und Synchronisation"),
                footer:Text("Auto-Update und Echtzeit-Synchronisation wirken sich auf den Energiebedarf aus")
                    .font(.caption)
            ) {
                
                

                VStack {
                    Spacer()
                    Spacer()

                    TextField ( "http://server.domain/ords/dscan", text: $serverurl )
                        .disableAutocorrection(true)
                        .font(.subheadline)
                    
                    Spacer()
                    Spacer()

                    Button ( action: {
                        app.publishInfo(
                            url: URL(string:serverurl),
                            webview:  true
                        ) }
                    ) {
                        Label("Test", systemImage: "safari")
                            
                    }
                    .buttonStyle(.bordered)
                    .disabled (URL(string:serverurl) == nil)
                        


                    Spacer()
                    Spacer()

                }

                VStack {
                    Slider (
                        value: $syncRange,
                        in: 1...26280,
                        step: 1,
                        label: { Text("Stunden") }
                    )
                    let futureDate = Calendar.current.date(byAdding: DateComponents(hour:Int(syncRange * -1)), to: currentDate) ?? .now
                    
                    Text("Übernehme Daten seit \(futureDate.formatted(.relative(presentation: .named)))")
                        .font(.subheadline)

                }


                VStack {
                    Spacer()
                    Spacer()

                    Toggle("Auto-Update", isOn: $autoUpdate)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Spacer()


                        Slider (
                            value: $autoUpdateSeconds,
                            in: 10...300,
                            step: 10,
                            label: { Text("Time") }
                        )
                        .disabled(!autoUpdate)
                        
                        Spacer()
                  

                        Toggle("Echtzeit-Synchronisation", isOn: $longpollMode)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            .disabled(!autoUpdate)
                    
                        Slider (
                            value: $longpollSeconds,
                            in: 10...900,
                            step: 10,
                            label: { Text("Sekunden") }
                        )
                        .disabled(!autoUpdate)
                        .disabled(!longpollMode)
                    
                        Text((autoUpdate == false ? "Manuelle Aktualisierung" :
                             (longpollMode ? "Echtzeit-Synchronisierung für  \(longpollSeconds.formatted()) Sekunden nach jedem Änderungs-Ereignis, danach " : "")
                                + "Auto-Update alle \(autoUpdateSeconds.formatted()) Sekunden"
                         ))
                        .frame(height: 100)
                        .multilineTextAlignment(.leading)
                        .font(.footnote)
                }

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


            Section (
                header:Text("Barcode and 2D-Code types"),
                footer:Text("Selecting only the types you need could improve accuracy and performance")
            ) {
                VStack {
                    Toggle("Code 39",                                  isOn: $bs_code39                  ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Code 39 with a checksum",                  isOn: $bs_code39Checksum          ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Interleaved 2 of 5 (ITF)",                 isOn: $bs_i2of5                   ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Interleaved 2 of 5 (ITF) with a checksum", isOn: $bs_i2of5Checksum           ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Code 128",                                 isOn: $bs_code128                 ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Codabar",                                  isOn: $bs_codabar                 ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("EAN-8",                                    isOn: $bs_ean8                    ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("EAN-13",                                   isOn: $bs_ean13                   ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                VStack {
                    Toggle("UPC-E",                                    isOn: $bs_upce                    ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Aztec",                                    isOn: $bs_aztec                   ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("QR",                                       isOn: $bs_qr                      ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("MicroQR",                                  isOn: $bs_microQR                 ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Data Matrix",                              isOn: $bs_dataMatrix              ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("PDF417",                                   isOn: $bs_pdf417                  ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("MicroPDF417",                              isOn: $bs_microPDF417             ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                VStack {
                    Toggle("ITF-14",                                   isOn: $bs_itf14                   ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Code 39 Full ASCII",                       isOn: $bs_code39FullASCII         ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Code 39 Full ASCII with a checksum",       isOn: $bs_code39FullASCIIChecksum ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Code 93",                                  isOn: $bs_code93                  ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("Code 93i",                                 isOn: $bs_code93i                 ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("GS1 DataBar",                              isOn: $bs_gs1DataBar              ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("GS1 DataBar Expanded",                     isOn: $bs_gs1DataBarExpanded      ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("GS1 DataBar Limited",                      isOn: $bs_gs1DataBarLimited       ).toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
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
                stops: [SwiftUI.Gradient.Stop(color: Color("Color"), location: 0.0),SwiftUI.Gradient.Stop(color: Color("Color-1"), location: 1.0)],
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

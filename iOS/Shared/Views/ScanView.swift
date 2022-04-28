//
//  ScanView.swift
//  dscan
//
//  Created by Matthias Schulze on 26.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct ScanView: View {
    @State private var showScannerSheet = true
    @State private var texts:[ScanDataOrig] = []
    var body: some View {
        NavigationView{
            VStack{
                if texts.count > 0{
                    List{
                        ForEach(texts){text in
                            NavigationLink(
                                destination:ScrollView{Text(text.content)},
                                label: {
                                    Text(text.content).lineLimit(1)
                                })
                        }
                    }
                }
                else{
                    Text("No scan yet").font(.title)
                }
            }
                .navigationTitle("Scan OCR")
                .navigationBarItems(trailing: Button(action: {
                    self.showScannerSheet = true
                }, label: {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.title)
                })
                .sheet(isPresented: $showScannerSheet, content: {
                    self.makeScannerView()
                })
                )
        }
    }
    private func makeScannerView()-> ScannerView {
        ScannerView(completion: { scanData in
            print("got \(scanData?.count ?? 0) scans")
            self.showScannerSheet = false
        })
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}

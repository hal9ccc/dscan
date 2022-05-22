//
//  WebView.swift
//  dscan
//
//  Created by Matthias Schulze on 22.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import WebKit
 
struct WebView: UIViewRepresentable {
 
    var url: URL
    
    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"
 
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
 
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(url: URL(string: "www.google.de")!)
    }
}

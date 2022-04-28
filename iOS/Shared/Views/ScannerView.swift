//
//  ScannerView.swift
//  dscan
//
//  Created by Matthias Schulze on 26.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import UIKit
import Vision
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    @EnvironmentObject var scanData: ScanData

    private let completionHandler: ([MediaProperties]?) -> Void
     
    init(completion: @escaping ([MediaProperties]?) -> Void) {
        self.completionHandler = completion
    }
     
    typealias UIViewControllerType = VNDocumentCameraViewController
     
    func makeUIViewController(context: UIViewControllerRepresentableContext<ScannerView>) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
     
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<ScannerView>) {}
     
    func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completionHandler)
    }
     
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var mediaProvider:  MediaProvider  = .shared
        
        var scanData: ScanData = ScanData()

        private let completionHandler: ([MediaProperties]?) -> Void
        
//        private var metadata: MMMetadata = MMMetadata()
//        private var textRecognitionRequest = VNRecognizeTextRequest()
//        private var barcodeRecognitionRequest = VNDetectBarcodesRequest()

         
        init(completion: @escaping ([MediaProperties]?) -> Void) {
            self.completionHandler = completion
        }
         
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("got \(scan.pageCount) pages")

            // create new ScanData before populating with info
            scanData = ScanData()
            
            let d = Date()
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd HH:mm:ss.SSSS"
//            let ts = df.string(from: d)
//            df.dateFormat = "yMMdd_HH:mm:ss.SSSS"
            
            for pageNumber in 0 ..< scan.pageCount {
                let m = MediaProperties (
                  id:                     "",
                  set:                    "\(df.string(from: d))",
                  idx:                    pageNumber,
                  time:                   d,
                  title:                  scan.title,
                  device:                 UIDevice.current.name,
                  filename:               "\(df.string(from: d))_\(pageNumber + 1)",
                  code:                   "",
                  person:                 "",
                  company:                "",
                  carrier:                "",
                  location:               "",
                  img:                    "",
                  recognizedCodesJson:    "",
                  recognizedTextJson:     "",
                  imageData:              scan.imageOfPage(at: pageNumber).jpegData(compressionQuality: 1) ?? Data()
                )
                
                scanData.mediaPropertiesList.append(m)
                print(m)
                //self.processImage(image: image, filename: filename, title: scan.title, index: pageNumber, timestamp: ts)
            }
            
            //print("Received \(mediaPropertiesList.count) records.")

            // Import the JSON into Core Data.
            //print("Start importing data to the store...")
            //await mediaProvider.importMedia(from: mediaPropertiesList)
        }
         
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completionHandler(nil)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera view controller did finish with error ", error)
            completionHandler(nil)
        }

    }
}


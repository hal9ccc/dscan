//
//  ScannerView.swift
//  dscan
//
//  Created by Matthias Schulze on 26.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
//import UIKit
import Vision
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
//    @EnvironmentObject var scanData: ScanData

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

        @AppStorage("CompressionQuality")
        private var compressionQuality: Double = 0.5

        private let completionHandler: ([MediaProperties]?) -> Void

        init(completion: @escaping ([MediaProperties]?) -> Void) {
            self.completionHandler = completion
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("got \(scan.pageCount) pages")

            let d = Date()
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd HH:mm:ss.SSSS"
            let idf = DateFormatter()
            idf.dateFormat = "yMMddHHmmss.SSSS"
//            let ts = df.string(from: d)
//            df.dateFormat = "yMMdd_HH:mm:ss.SSSS"
            
            // for displaying a day in local format
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyyMMdd"

//            dayFormatter.dateStyle = .full
//            dayFormatter.timeStyle = .none
//            dayFormatter.locale = Locale.current

            var mediaPropertiesList = [MediaProperties]()

            for pageNumber in 0 ..< scan.pageCount {
                let m = MediaProperties (
                  id:                     "\(idf.string(from: d))_\(pageNumber + 1)",
                  set:                    "\(df.string(from: d))",
                  idx:                    pageNumber,
                  cid:                    0,
                  day:                    dayFormatter.string(from: d),
                  hidden:                 false,
                  status:                 "scanned",
                  type:                   "scan",
                  time:                   d,
                  title:                  scan.title,
                  device:                 UIDevice.current.name,
                  info1:                  "",
                  info2:                  "",
                  info3:                  "",
                  info4:                  "",
                  filename:               "\(df.string(from: d))_\(pageNumber + 1)",
                  code:                   "␀",
                  person:                 "␀",
                  company:                "␀",
                  carrier:                "␀",
                  location:               "␀",
                  img:                    "␀",
                  fulltext:               "",
//                  recognizedCodesJson:    "␀",
//                  recognizedTextJson:     "␀",
                  imageData:              scan.imageOfPage(at: pageNumber).jpegData(compressionQuality: 1) ?? Data()
//                  uiImage:                scan.imageOfPage(at: pageNumber)
                )

                mediaPropertiesList.append(m)
                print(pageNumber)
            }

            print("Received \(mediaPropertiesList.count) records.")

            controller.dismiss(animated: false, completion: nil)
            
            completionHandler(mediaPropertiesList)


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


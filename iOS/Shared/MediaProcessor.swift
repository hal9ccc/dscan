//
//  ScanData.swift
//
//  dscan
//
//  observable text recognition, barcode detection and file upload
//
//  Created by Matthias Schulze on 26.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import OSLog
import CoreData
import SwiftUI
import Vision
import VisionKit


class MediaProcessor: ObservableObject {
    
    var mediaProvider: MediaProvider = .shared

    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"

    @AppStorage("CompressionQuality")
    private var compressionQuality = 1

    var textRecognitionRequest    = VNRecognizeTextRequest()
    var detectBarcodesRequest     = VNDetectBarcodesRequest()

    @Published var isUploadingImage:        Bool        = false
    @Published var isDetectingBarcodes:     Bool        = false
    @Published var isRecognizingTexts:      Bool        = false
    @Published var isUploadingData:         Bool        = false

    var metadata:                MMImage     = MMImage()
    var idx:                     Int         = 0

    var title:                   String      = ""
    var timestamp:               Date        = .distantPast

    var ordsError:               OrdsError?  = nil
    var error:                   Error?      = nil

    // wait for two background requests to finish
    // see https://dev.to/nemecek_f/swift-easy-way-to-wait-for-multiple-background-tasks-to-finish-2jk1
    let refreshGroup            = DispatchGroup()
    
    let logger = Logger(subsystem: "de.hal9ccc.dscan", category: "processing")

    init () {

        textRecognitionRequest = VNRecognizeTextRequest ( completionHandler: { (request, error) in
            
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    let maximumCandidates = 1

                    for observation in requestResults {
                        guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                        let bb = try? candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex)

                        let T = MMRecognizedText (
                            text:       candidate.string,
                            confidence: candidate.confidence,
                            x: Float((bb != nil) ? bb!.topLeft.x  : 0),
                            y: Float((bb != nil) ? bb!.topLeft.y  : 0),
                            w: Float((bb != nil) ? bb!.topRight.x : 0) - Float((bb != nil) ? bb!.topLeft.x    : 0),
                            h: Float((bb != nil) ? bb!.topLeft.y  : 0) - Float((bb != nil) ? bb!.bottomLeft.y : 0)
                        )

                        self.metadata.recognizedText.append(T);
                    }
                }
            }
            self.logger.debug ("got \(self.metadata.recognizedText.count) texts")
        })

        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        //textRecognitionRequest.recognitionLanguages


        detectBarcodesRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in

//            let f = [MMDetectedBarcode]()
            
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNBarcodeObservation] {

                    for observation in requestResults {
                        let C = MMDetectedBarcode (
                            payload:   observation.payloadStringValue ?? "",
                            symbology: observation.symbology.rawValue.replacingOccurrences(of: "VNBarcodeSymbology", with: "")
                        )
                        self.metadata.detectedBarcodes.append(C);
                    }
                }
            }
            self.logger.debug ("got \(self.metadata.detectedBarcodes.count) codes")
        })
        detectBarcodesRequest.revision    = VNDetectBarcodesRequestRevision2
        detectBarcodesRequest.symbologies = [.code128, .code39, .code39Checksum, .dataMatrix, .pdf417, .qr, .aztec, .ean13, .i2of5, .upce ]
    }

    /*
    ** ***********************************************************************************************
    */
    func processAllImages(predicate: String = "imageData != nil", completion: @escaping () -> Void) {
        //
        // Serialisiert OCR + Barcodeerkennung + Upload von .jpg + Upload von .json
        //
        // Die Verarbeitung erfolgt im Hintergrund, der Main-Thread wird nach jedem Upload
        // aktualisiert
        //
        logger.info("processing images")
        
        var media2Process = [Media]()
        
        let mediaFetch = Media.createFetchRequest()
        mediaFetch.predicate = NSPredicate(format: predicate)
        
        let sort_time = NSSortDescriptor(key: "time", ascending: true)
        let sort_idx  = NSSortDescriptor(key: "idx",  ascending: true)
        mediaFetch.sortDescriptors = [sort_time, sort_idx]


        refreshGroup.notify (queue: DispatchQueue.global()) { 
            completion()
        }


        do {
            media2Process = try MediaProvider.shared.container.viewContext.fetch(mediaFetch)
            logger.debug("Got \(media2Process.count) documents")

            // signal we're busy
            isUploadingImage = true

            // high-priority background threads
            DispatchQueue.global(qos: .userInitiated).async {

                media2Process.forEach {image in
                    self.refreshGroup.enter()
                    self.processImage(image, completion: { self.refreshGroup.leave() })
                }
            }

            // signal we're done
            isUploadingImage = false

        } catch {
            logger.critical("Fetch failed")
        }
    }
    
    /*
    ** ***********************************************************************************************
    */
//    init(completion: @escaping ([MediaProperties]?) -> Void) {
//        self.completionHandler = completion
//    }

    func processImage(_ media: Media, completion: @escaping () -> Void) {
        
        logger.info("analyzing \(media.filename)...")

        var jsondata: Data = Data()

        reset()

        let uiImage = UIImage(data: media.imageData ?? Data())
        if uiImage == nil {
            return// media
        }

        guard let cgImage = uiImage!.cgImage else {
            print("Failed to get cgimage from input image")
            return// media
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([detectBarcodesRequest, textRecognitionRequest])
        } catch {
            self.logger.error("\(String(describing: error))")
            self.error = error
        }

        self.logger.debug("imagerequests completed, uploading data...")

        do {
            jsondata = try JSONEncoder().encode(self.metadata)
//            self.logger.debug("data: \(String(data: jsondata, encoding: .utf8)!)")
        } catch {
            self.error = error
        }

        let uploadGroup = DispatchGroup()

        // called when both uploads complete
        uploadGroup.notify (queue: DispatchQueue.global()) {
            
//            self.logger.debug("uploads for \(media.filename) completed, deleting original image...")
//            media.imageData = nil
////            MediaProvider.shared.container.viewContext.delete(media)
//            try? MediaProvider.shared.container.viewContext.save()

            completion()
        }
        
        uploadGroup.enter()
        self.uploadData  (
            data:           jsondata,
            filename:       media.filename,
            title:          media.title,
            idx:            Int(media.idx),
            timestamp:      media.time,
            completion:     {
                self.logger.debug("json upped")
                uploadGroup.leave()
            }
        )

        uploadGroup.enter()
        self.uploadImage (
            image:          uiImage!,
            filename:       media.filename,
            title:          media.title,
            idx:            Int(media.idx),
            timestamp:      media.time,
            completion:     {
                self.logger.debug("json upped")
                uploadGroup.leave()
            }
        )
    }

    /*
    ** ***********************************************************************************************
    */
    func uploadData (data: Data, filename: String, title: String, idx: Int, timestamp: Date, completion: @escaping () -> Void) {
//
//        self.isUploadingData = true

        let url = URL(string: "\(serverurl)/media/files/")!
        let headers: HTTPHeaders = [
            "Content-Type"   : "text/json",
            "filename"       : filename,
            "type"           : "scan",
            "title"          : title,
            "idx"            : idx.formatted(),
            "timestamp"      : timestamp.formatted(.iso8601),
            "device"         : UIDevice.current.name
        ]

        let jsonRequest = Upload(data: data, to: url, with: headers, using:"POST")

        jsonRequest.upload { (result) in
            
            completion()
            
            switch result {
                case .success(let value):
//                    self.isUploadingData = false
                    assert(value.statusCode == 201)

                case .failure(let error):
//                    self.isUploadingData = false
                    print(error.localizedDescription)
            }
        }
    }


    /*
    ** ***********************************************************************************************
    */
    func uploadImage (image: UIImage, filename: String, title: String, idx: Int, timestamp: Date, completion: @escaping () -> Void) {
//
//        self.isUploadingImage = true

        let url = URL(string: "\(serverurl)/media/files/")!
        let headers: HTTPHeaders = [
            "Content-Type"   : "image/jpg",
            "filename"       : "\(filename.replacingOccurrences(of: ".json", with: ".jpg"))",
            "type"           : "scan",
            "title"          : title,
            "idx"            : idx.formatted(),
            "timestamp"      : timestamp.formatted(.iso8601),
            "device"         : UIDevice.current.name
        ]

        guard let imgData = image.jpegData(compressionQuality: CGFloat(compressionQuality)) else { return }

        let imgRequest = Upload(data: imgData, to: url, with: headers, using:"POST")

        imgRequest.upload { (result) in

            completion()
            
            switch result {
                case .success(let value):
//                    self.isUploadingImage = false
                    assert(value.statusCode == 201)

                case .failure(let error):
//                    self.isUploadingImage = false
                    print(error.localizedDescription)
            }
        }
    }
    

    func reset () {
        metadata                = MMImage()

        ordsError               = nil
        error                   = nil
    }

}


struct ScanDataOrig:Identifiable {
    var id = UUID()
    let content:String

    init(content:String) {
        self.content = content
    }
}


/*
** Image- and JSON-Upload
*/

struct OrdsError: Codable {
    var message: String
    var errorstack: String
}

struct MMDetectedBarcode: Codable {
    var payload: String
    var symbology: String
}

struct MMRecognizedText: Codable {
    var text: String
    var confidence: Float
    var x: Float
    var y: Float
    var w: Float
    var h: Float
}

struct MMImage: Codable {
    var id = UUID()
    var recognizedText:  [MMRecognizedText] = [MMRecognizedText]()
    var detectedBarcodes: [MMDetectedBarcode] = [MMDetectedBarcode]()
}

//struct ScanData: Codable {
//    var images: [MMImage] = [MMImage]()
//}



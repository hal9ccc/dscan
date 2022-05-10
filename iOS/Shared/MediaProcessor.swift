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
//    @Published var mediaPropertiesList = [MediaProperties]()
    
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

    @Published var metadata:                MMImage     = MMImage()
    @Published var idx:                     Int         = 0
    @Published var filename:                String      = ""
    @Published var title:                   String      = ""
    @Published var timestamp:               Date        = .distantPast

    @Published var ordsError:               OrdsError?  = nil
    @Published var error:                   Error?      = nil

    @Published var detectedBarcodes:        Int?        = nil
    @Published var detectedTexts:           Int?        = nil

    // wait for two background requests to finish
    // see https://dev.to/nemecek_f/swift-easy-way-to-wait-for-multiple-background-tasks-to-finish-2jk1
    
    var imageRequestGroup   = DispatchGroup()
    var uploadGroup         = DispatchGroup()
    
    let logger = Logger(subsystem: "de.hal9ccc.dscan", category: "processing")

    init () {

        textRecognitionRequest = VNRecognizeTextRequest ( completionHandler: { (request, error) in

            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
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
            }

            self.imageRequestGroup.leave()
        })

        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        //textRecognitionRequest.recognitionLanguages


        detectBarcodesRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNBarcodeObservation] {
                    DispatchQueue.main.async {
                        for observation in requestResults {

                            let C = MMDetectedBarcode (
                                payload:   observation.payloadStringValue ?? "",
                                symbology: observation.symbology.rawValue.replacingOccurrences(of: "VNBarcodeSymbology", with: "")
                            )

                            self.metadata.detectedBarcodes.append(C);
                        }

                        self.detectedBarcodes = self.metadata.detectedBarcodes.count

                    }
                }
            }
            print ("Barcoderesults", self.metadata.detectedBarcodes)
            self.imageRequestGroup.leave()
        })
        detectBarcodesRequest.revision    = VNDetectBarcodesRequestRevision2
        detectBarcodesRequest.symbologies = [.code128, .code39, .code39Checksum, .dataMatrix, .pdf417, .qr, .aztec, .ean13, .i2of5, .upce ]
        detectBarcodesRequest.usesCPUOnly = true
    }

    func reset () {
        isUploadingImage        = false
        isDetectingBarcodes     = false
        isRecognizingTexts      = false
        isUploadingData         = false

        metadata                = MMImage()
        idx                     = 0
        filename                = ""
        title                   = ""
        timestamp               = .distantPast

        ordsError               = nil
        error                   = nil

        detectedBarcodes        = nil
        detectedTexts           = nil
    }


    /*
    ** ***********************************************************************************************
    */
    func processAllImages() {
        logger.info("processing all images")
        
        var media2Process = [Media]()
        
        //        let moc = MediaProvider.shared.container.viewContext
        let mediaFetch = Media.createFetchRequest()
        mediaFetch.predicate = NSPredicate(format: "imageData != nil")
        
        let sort = NSSortDescriptor(key: "time", ascending: false)
        mediaFetch.sortDescriptors = [sort]

        do {
            media2Process = try MediaProvider.shared.container.viewContext.fetch(mediaFetch)
            logger.info("Got \(media2Process.count) documents")

            let f = media2Process.map {
//                if $0.imageData != nil {
                    return processImage($0)
//                }
            }

            logger.info("processed \(String.init(describing: f))")

        } catch {
            print("Fetch failed")
        }
    }
    
    /*
    ** ***********************************************************************************************
    */
    func processImage(_ media: Media)  -> Media {

        reset()
        
        let uiImage = UIImage(data: media.imageData ?? Data())!
        guard let cgImage = uiImage.cgImage else {
            print("Failed to get cgimage from input image")
            return media
        }

        self.filename   = filename
        self.title      = title
        self.idx        = idx
        self.timestamp  = timestamp

        self.isRecognizingTexts  = true
        self.isDetectingBarcodes = true
        self.imageRequestGroup   = DispatchGroup()
        self.uploadGroup         = DispatchGroup()

        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            self.imageRequestGroup.enter()
            self.imageRequestGroup.enter()
            try handler.perform([detectBarcodesRequest, textRecognitionRequest])

        } catch {
            self.error = error
        }


        // called when both image-requests complete
        self.imageRequestGroup.notify (queue: .main) {

            print ("imagerequests completed, uploading data...")
            self.isRecognizingTexts = false
            self.isDetectingBarcodes = false
            
            do {
                self.isUploadingData = true
                let data = try JSONEncoder().encode(self.metadata)
                print(String(data: data, encoding: .utf8)!)

                self.uploadGroup.enter()
                self.uploadGroup.enter()
                self.uploadData  (data:  data,    filename: media.filename, title: media.title, idx: Int(media.idx), timestamp: media.time)
                self.uploadImage (image: uiImage, filename: media.filename, title: media.title, idx: Int(media.idx), timestamp: media.time)
                
            } catch {
                self.error = error
            }
        }


        // called when both uploads complete
        self.uploadGroup.notify (queue: .main) {
            
            print ("uploads for \(media.filename) completed, deleting original...")
//            withAnimation { self.mediaProvider.deleteMedia(identifiedBy: [media.objectID]) }
//
//            // refresh from server
//            Task {
//                do {
//                    print ("refreshing from server...")
//                    try await self.mediaProvider.fetchMedia()
//                    // lastUpdated = Date().timeIntervalSince1970
//                } catch {
//                    self.error = error as? DscanError ?? .unexpectedError(error: error)
//                    //  self.hasError = true
//                }
//            }
        }
        
        return media
    }

    /*
    ** ***********************************************************************************************
    */
    func uploadData (data: Data, filename: String, title: String, idx: Int, timestamp: Date) {

        self.isUploadingData = true

        let url = URL(string: "\(serverurl)/media/files/")!
        let headers: HTTPHeaders = [
            "Content-Type"   : "text/json",
            "filename"       : "\(filename).json",
            "type"           : "scan",
            "title"          : title,
            "idx"            : idx.formatted(),
            "timestamp"      : timestamp.formatted(.iso8601),
            "device"         : UIDevice.current.name
        ]

        let jsonRequest = Upload(data: data, to: url, with: headers, using:"POST")

        jsonRequest.upload { (result) in
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
    func uploadImage (image: UIImage, filename: String, title: String, idx: Int, timestamp: Date) {

        self.isUploadingImage = true

        let url = URL(string: "\(serverurl)/media/files/")!
        let headers: HTTPHeaders = [
            "Content-Type"   : "image/jpg",
            "filename"       : "\(filename).jpg",
            "type"           : "scan",
            "title"          : title,
            "idx"            : idx.formatted(),
            "timestamp"      : timestamp.formatted(.iso8601),
            "device"         : UIDevice.current.name
        ]

        guard let imgData = image.jpegData(compressionQuality: CGFloat(compressionQuality)) else { return }

        let imgRequest = Upload(data: imgData, to: url, with: headers, using:"POST")

        imgRequest.upload { (result) in
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



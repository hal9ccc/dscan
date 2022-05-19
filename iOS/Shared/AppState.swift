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


/// https://stackoverflow.com/a/70045158/701753
//@MainActor
class AppState: ObservableObject {

    var mediaProvider: MediaProvider = .shared

    @AppStorage("ServerURL")
    private var serverurl = "http://localhost"

    @AppStorage("CompressionQuality")
    private var compressionQuality = 1

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


    var textRecognitionRequest    = VNRecognizeTextRequest()
    var detectBarcodesRequest     = VNDetectBarcodesRequest()

    @Published var isLoading:               Bool            = false
    @Published var isSync:                  Bool            = false
    @Published var isError:                 Bool            = false
    @Published var isUploadingImage:        Bool            = false
    @Published var isDetectingBarcodes:     Bool            = false
    @Published var isRecognizingTexts:      Bool            = false
    @Published var isUploadingData:         Bool            = false

    @Published var lastUpdated:             Date            = Date.distantPast
    @Published var section:                 MediaSection    = MediaSection.all
    @Published var sectionKey:              String          = ""

    @Published var numSections:             Int             = 0
    @Published var numItems:                Int             = 0
    @Published var numShowing:              Int             = 0
    @Published var numSelected:             Int             = 0


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
        detectBarcodesRequest.symbologies = getBarcodeSymbologies()
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
            var A: [Media] = []

            DispatchQueue.global(qos: .userInitiated).async {
                media2Process.forEach { image in
                    self.refreshGroup.enter()
                    self.processImage(image, completion: {
                        A.append(image)
                        image.imageData = nil;
                        try? MediaProvider.shared.container.viewContext.save()
                        self.refreshGroup.leave()
                    })
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
                self.logger.debug("json \(media.filename) upped")
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
                self.logger.debug("img \(media.filename) upped")
                uploadGroup.leave()
            }
        )
    }

    /*
    ** ***********************************************************************************************
    */
    func uploadData (data: Data, filename: String, title: String, idx: Int, timestamp: Date, completion: @escaping () -> Void) {

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
                    assert(value.statusCode == 201)

                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }


    /*
    ** ***********************************************************************************************
    */
    func uploadImage (image: UIImage, filename: String, title: String, idx: Int, timestamp: Date, completion: @escaping () -> Void) {

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
                    assert(value.statusCode == 201)

                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }


    func reset () {
        metadata                = MMImage()

        ordsError               = nil
        error                   = nil
    }

    func publishInfo (
        ts:            Date?=nil,
        sect:          MediaSection?=nil,
        key:           String?=nil,
        sections:      Int?=nil,
        items:         Int?=nil,
        showing:       Int?=nil,
        selected:      Int?=nil,
        loading:       Bool?=nil,
        sync:          Bool?=nil,
        error:         Bool?=nil
    ) -> Bool {
        lastUpdated  = ts       ?? lastUpdated
        section      = sect     ?? section
        sectionKey   = key      ?? sectionKey
        numSections  = sections ?? numSections
        numItems     = items    ?? numItems
        numShowing   = showing  ?? numShowing
        numSelected  = selected ?? numSelected
        isLoading    = loading  == nil ? isLoading : loading ?? false
        isSync       = sync     == nil ? isSync    : sync    ?? false
        isError      = error    == nil ? isError   : error   ?? false

        //logger.debug("sect:\(self.numSections) items:\(self.numItems) shown:\(self.numShowing) selected:\(self.numSelected) loading:\(self.isLoading) syync:\(self.isSync) err: \(self.isError)")
        return true
    }
    

    /*
    ** ***********************************************************************************************
    */
    func getBarcodeSymbologies () -> [VNBarcodeSymbology] {
        var f: [VNBarcodeSymbology] = []
        
        if bs_aztec                    { f.append(.aztec)                   }
        if bs_code39                   { f.append(.code39)                  }
        if bs_code39Checksum           { f.append(.code39Checksum)          }
        if bs_code39FullASCII          { f.append(.code39FullASCII)         }
        if bs_code39FullASCIIChecksum  { f.append(.code39FullASCIIChecksum) }
        if bs_code93                   { f.append(.code93)                  }
        if bs_code93i                  { f.append(.code93i)                 }
        if bs_code128                  { f.append(.code128)                 }
        if bs_dataMatrix               { f.append(.dataMatrix)              }
        if bs_ean8                     { f.append(.ean8)                    }
        if bs_ean13                    { f.append(.ean13)                   }
        if bs_i2of5                    { f.append(.i2of5)                   }
        if bs_i2of5Checksum            { f.append(.i2of5Checksum)           }
        if bs_itf14                    { f.append(.itf14)                   }
        if bs_pdf417                   { f.append(.pdf417)                  }
        if bs_qr                       { f.append(.qr)                      }
        if bs_upce                     { f.append(.upce)                    }
        if bs_codabar                  { f.append(.codabar)                 }
        if bs_gs1DataBar               { f.append(.gs1DataBar)              }
        if bs_gs1DataBarExpanded       { f.append(.gs1DataBarExpanded)      }
        if bs_gs1DataBarLimited        { f.append(.gs1DataBarLimited)       }
        if bs_microPDF417              { f.append(.microPDF417)             }
        if bs_microQR                  { f.append(.microQR)                 }

        return f;
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



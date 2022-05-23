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


class DScanApp: ObservableObject {

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

    @Published var isLoading              = false
    @Published var isSync                 = false
    @Published var isError                = false
    @Published var isUploadingImage       = false
    @Published var isDetectingBarcodes    = false
    @Published var isRecognizingTexts     = false
    @Published var isUploadingData        = false

    @Published var lastRedraw            = Date.now
    @Published var lastSync               = Date.now
    @Published var lastChange             = Date.now

    @Published var section                = MediaSection.all
    @Published var sectionKey             = ""

    @Published var numCid                 = 0
    @Published var numSections            = 0
    @Published var numItems               = 0
    @Published var numShowing             = 0
    @Published var numSelected            = 0

    @Published var webviewUrl:              URL             = URL(string: "about://")!
    @Published var webviewOn:               Bool            = false

    
    var metadata:                MMImage     = MMImage()
    var idx:                     Int         = 0

    var title:                   String      = ""
    var timestamp:               Date        = .distantPast

    var ordsError:               OrdsError?  = nil
    var error:                   Error?      = nil
    
    var autoSyncLocked                       = false


    @AppStorage("LastChange")
    private var lastChangeStr:              String = ""

    @AppStorage("AutoUpdate")
    private var autoUpdate:                 Bool = true
    
    @AppStorage("AutoUpdateSeconds")
    private var autoUpdateSeconds:          Double = 10
    
    @AppStorage("LongpollMode")
    private var longpollMode:               Bool = true
    
    @AppStorage("LongpollSeconds")
    private var longpollSeconds:            Double = 60
    

    // wait for two background requests to finish
    // see https://dev.to/nemecek_f/swift-easy-way-to-wait-for-multiple-background-tasks-to-finish-2jk1
    let refreshGroup            = DispatchGroup()

    let logger                  = Logger(subsystem: "de.hal9ccc.dscan", category: "DScanApp")
    let updateFeedback          = UIImpactFeedbackGenerator(style: .rigid)

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
    ** ********************************************************************************************
    */
    func onSyncTimer () {
        
//        print (Locale.current)
        
        if isLoading {
//            logger.debug("isLoading")
            return
        }
        if isSync    {
//            logger.debug("isSync")
            return
        }

        if autoSyncLocked    {
            logger.debug("autoSyncLocked")
            return
        }
       
        
        
//        private var autoUpdate:                 Bool = true
//        private var autoUpdateSeconds:          Double = 10
//        private var longpollMode:               Bool = true
//        private var longpollSeconds:            Double = 60
        
        
        if autoUpdate {
            let secondsSincelastSync    = Date.now.timeIntervalSinceReferenceDate - lastSync.timeIntervalSinceReferenceDate
            let secondsSincelastChange  = Date.now.timeIntervalSinceReferenceDate - lastChange.timeIntervalSinceReferenceDate
//            logger.debug("secondsSincelastChange: \(secondsSincelastChange)")
//            logger.debug("secondsSincelastSync: \(secondsSincelastSync)")

            
            if longpollMode && secondsSincelastChange < longpollSeconds {
                // schedule the next long-poll request
                autoSyncLocked = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Task { self.fetchMedia(pollingFor: 10, _force: true) }
                }

            }
            else {
                if secondsSincelastSync > autoUpdateSeconds {
                    // schedule the poll request
                    autoSyncLocked = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        Task { self.fetchMedia(_force: true) }
                    }
                }
            }
        }
    }


    /*
    ** ********************************************************************************************
    */
    func changeOccured () {
        logger.info("changeOccured")

        updateFeedback.impactOccurred()

        publishInfo(tsChange:Date.now)
        forceRedraw()
    }

    
        
    /*
    ** ********************************************************************************************
    */
    func fetchMedia(pollingFor pollSeconds: Int = -1, complete: Bool = false, _force: Bool = false) {

        if isLoading && !_force { return }
        if isSync    && !_force { return }

        Task {
            do {
                
                self.publishInfo(
                    loading: pollSeconds < 1 ? true : false,
                    sync:    pollSeconds > 0 ? true : false
                )

                /// REST query
                let n = try await mediaProvider.fetchMedia(pollingFor: pollSeconds, complete: complete)

                publishInfo(tsSync:Date.now, loading: false, sync: false)
                
                // n becomes the number of rows fetched
                if n > 0 {
                    
                    self.changeOccured()
                    
//
//                    // schedule an immediate long-poll when we got rows
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        Task { self.fetchMedia(pollingFor: 30, _force: true) }
//                    }
                }
                else {
//                    // schedule a fetch in a few seconds
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
//                        Task { self.fetchMedia(pollingFor: 0, _force: true) }
//                    }
                }
                
                autoSyncLocked = false
                
            } catch {
                logger.debug("fetch failed")
            }
        }
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

            // high-priority background thread
            DispatchQueue.global(qos: .userInteractive).async {
                media2Process.forEach { image in
                    self.refreshGroup.enter()
                    self.processImage(image, completion: {
                        self.forceRedraw()
                        self.refreshGroup.leave()
                    })
                }
            }
        }
        catch {
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
            logger.debug("Failed to get cgimage from input image")
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
                    self.logger.debug("\(error.localizedDescription)")
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
                self.logger.debug("\(error.localizedDescription)")
            }
        }
    }


    func reset () {
        metadata                = MMImage()

        ordsError               = nil
        error                   = nil
    }

    /*
    ** ***********************************************************************************************
    */
    func forceRedraw () {
        // changes app.currentTime, which is part of appState and must be included
        // in all Components that need a forced redraw
        self.publishInfo(now: Date.now)
    }


    /*
    ** ***********************************************************************************************
    */
    func publishInfo (
        now:           Date?=nil,
        tsSync:        Date?=nil,
        tsChange:      Date?=nil,
        cid:           Int?=nil,
        sect:          MediaSection?=nil,
        key:           String?=nil,
        sections:      Int?=nil,
        items:         Int?=nil,
        showing:       Int?=nil,
        selected:      Int?=nil,
        loading:       Bool?=nil,
        sync:          Bool?=nil,
        error:         Bool?=nil,
        url:           URL?=nil,
        webview:       Bool?=nil,

        _canPush:      Bool?=true
    ) {

        //logger.debug("publishInfo: isMainThread=\(Thread.current.isMainThread)")

        if Thread.current.isMainThread {
//            logger.debug("= = = = = MAIN THREAD = = = = =")

//            if loading  != nil {  logger.debug("loading:\(   String(describing: loading    ))") }
            if tsSync   != nil {  logger.debug("tsSync:\(    String(describing: tsSync     ))") }
            if tsChange != nil {  logger.debug("tsChange:\(  String(describing: tsChange   ))") }
            if key      != nil {  logger.debug("key:\(       String(describing: key        ))") }
            if cid      != nil {  logger.debug("cid:\(       String(describing: cid        ))") }
            if sect     != nil {  logger.debug("sect:\(      String(describing: sect       ))") }
            if items    != nil {  logger.debug("items:\(     String(describing: items      ))") }
            if sections != nil {  logger.debug("sections:\(  String(describing: sections   ))") }
            if selected != nil {  logger.debug("selected:\(  String(describing: selected   ))") }
            if url      != nil {  logger.debug("url:\(       String(describing: url        ))") }
            if webview  != nil {  logger.debug("webview:\(   String(describing: webview    ))") }

            self.lastRedraw  = now      ?? self.lastRedraw      //?? Date.now
            self.lastSync     = tsSync   ?? self.lastSync         //?? Date.now
            self.lastChange   = tsChange ?? self.lastChange      //?? Date.now
            self.section      = sect     ?? self.section          //?? MediaSection.default
            self.sectionKey   = key      ?? self.sectionKey       //?? ""
            self.numCid       = cid      ?? self.numCid           //?? 0
            self.numSections  = sections ?? self.numSections      //?? 0
            self.numItems     = items    ?? self.numItems         //?? 0
            self.numShowing   = showing  ?? self.numShowing       //?? 0
            self.numSelected  = selected ?? self.numSelected      //?? 0
            self.isLoading    = loading  == nil ? self.isLoading : loading!
            self.isSync       = sync     == nil ? self.isSync    : sync!
            self.isError      = error    == nil ? self.isError   : error!

            self.webviewUrl   = url      == nil ? self.webviewUrl: url!
            self.webviewOn    = webview  == nil ? self.webviewOn : webview!
            
            
            if tsSync != nil { onSyncTimer() } // HACK
            
        }
        else if _canPush ?? false  {
//            logger.debug("PUSHING CHANGES TO MAIN THREAD...")
            DispatchQueue.main.async {
                self.publishInfo (
                    now:           now,
                    tsSync:        tsSync,
                    tsChange:      tsChange,
                    cid:           cid,
                    sect:          sect,
                    key:           key,
                    sections:      sections,
                    items:         items,
                    showing:       showing,
                    selected:      selected,
                    loading:       loading,
                    sync:          sync,
                    error:         error,
                    _canPush:      false
                )
            }
        }
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



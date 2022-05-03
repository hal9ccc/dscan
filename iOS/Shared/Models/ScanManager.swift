//
//  ScanData.swift
//  dscan
//
//  Created by Matthias Schulze on 26.04.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import Vision
import VisionKit


class ScanManager: ObservableObject {
    @Published var mediaPropertiesList = [MediaProperties]()

    var textRecognitionRequest    = VNRecognizeTextRequest()
    var barcodeRecognitionRequest = VNDetectBarcodesRequest()
    
    var img: MMImage = MMImage()

    init () {
        
        textRecognitionRequest = VNRecognizeTextRequest (
            completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
                        print ("Textresults")
                        let maximumCandidates = 1

                        for observation in requestResults {
                            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                            let bb = try? candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex)
                            print(bb.debugDescription)

                            let T = MMRecognizedText (text:       candidate.string,
                             confidence: candidate.confidence,
                             x: Float((bb != nil) ? bb!.topLeft.x  : 0),
                             y: Float((bb != nil) ? bb!.topLeft.y  : 0),
                             w: Float((bb != nil) ? bb!.topRight.x : 0) - Float((bb != nil) ? bb!.topLeft.x    : 0),
                             h: Float((bb != nil) ? bb!.topLeft.y  : 0) - Float((bb != nil) ? bb!.bottomLeft.y : 0)
                            )
                            
                            self.img.recognizedText.append(T);
                        }
                    }
                }
            }
        })
        //barcodeRecognitionRequest.symbologies = [.QR, .Aztec, .Code128, .Code39, .Code39Checksum, .Code39FullASCII, .Code39FullASCIIChecksum, .Code93, .Code93i, .DataMatrix, .EAN8, .EAN13]

        
        barcodeRecognitionRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNBarcodeObservation] {
                    DispatchQueue.main.async {
                        print ("Barcoderesults")
                        //print (requestResults)

                        for observation in requestResults {
                           
                            let C = MMRecognizedCode (
                                payload:   observation.payloadStringValue ?? "",
                                symbology: observation.symbology.rawValue.replacingOccurrences(of: "VNBarcodeSymbology", with: "")
                            )

                            let existingCode = self.img.recognizedCodes.filter({$0.payload.contains(C.payload)})
                            print(existingCode)

                            self.img.recognizedCodes.append(C);
                        }
                    }
                }
            }
        })
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true

    }
        

    func processImage(image: UIImage, filename: String, title: String, index: Int, timestamp: String) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgimage from input image")
            return
        }
        
        //var img = MMImage()
        //metadata.images.append(img)

        if let imageData = image.jpegData(compressionQuality: 1.0) {
            let imageCFData = imageData as CFData
            if let cgImage = CGImageSourceCreateWithData(imageCFData, nil), let metaDict: NSDictionary = CGImageSourceCopyPropertiesAtIndex(cgImage, 0, nil) {
                let exifDict: NSDictionary = metaDict.object(forKey: kCGImagePropertyExifDictionary) as! NSDictionary
                print(exifDict)
            }
        }


        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([barcodeRecognitionRequest, textRecognitionRequest])
        } catch {
            print(error)
        }

        do {
            let data = try JSONEncoder().encode(img)
            print(String(data: data, encoding: .utf8)!)
            
            uploadData(data: data, filename: filename, title: title, index: index, timestamp: timestamp)
            
        } catch {
            print("an error")
        }

        uploadImage (image: image, filename: filename, title: title, index: index, timestamp: timestamp)
    }

    func uploadData (data: Data, filename: String, title: String, index: Int, timestamp: String) {

        let session = URLSession.shared
        let url = URL(string: "http://mbp-mschulze.local/ords/dscan/media/files/")!

        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        
        urlRequest.setValue("text/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(filename).json", forHTTPHeaderField: "filename")
        urlRequest.setValue("scan", forHTTPHeaderField: "type")
        urlRequest.setValue(title, forHTTPHeaderField: "title")
        urlRequest.setValue("\(index)", forHTTPHeaderField: "idx")
        urlRequest.setValue(timestamp, forHTTPHeaderField: "timestamp")
        urlRequest.setValue(UIDevice.current.name, forHTTPHeaderField: "device")
        urlRequest.httpBody = data

        let task = session.dataTask(with: urlRequest) { data, response, error in
            print ("completed \(filename)")
           
            //let str = String(decoding: data!, as: UTF8.self)
            let decoder = JSONDecoder()
            //print("BODY \n \(str)")

            if let ordsError = try? decoder.decode(OrdsError.self, from: data ?? Data()) {
                print(ordsError.message)
                if (ordsError.errorstack > "") { print(ordsError.errorstack) }
            }
        }

        task.resume()
        
    }


    func uploadImage (image: UIImage, filename: String, title: String, index: Int, timestamp: String) {

        guard let imgData = image.jpegData(compressionQuality: 0.2) else { return }
        
        let session = URLSession.shared
        let url = URL(string: "http://mbp-mschulze.local/ords/dscan/media/files/")!

        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        
        urlRequest.setValue("image/jpg", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(filename).jpg", forHTTPHeaderField: "filename")
        urlRequest.setValue("scan", forHTTPHeaderField: "type")
        urlRequest.setValue(title, forHTTPHeaderField: "title")
        urlRequest.setValue("\(index)", forHTTPHeaderField: "idx")
        urlRequest.setValue(timestamp, forHTTPHeaderField: "timestamp")
        urlRequest.setValue(UIDevice.current.name, forHTTPHeaderField: "device")
        urlRequest.httpBody = imgData

        let task = session.dataTask(with: urlRequest) { data, response, error in
            print ("completed \(filename)")
           
            //let str = String(decoding: data!, as: UTF8.self)
            let decoder = JSONDecoder()
            //print("BODY \n \(str)")

            if let ordsError = try? decoder.decode(OrdsError.self, from: data!) {
                print(ordsError.message)
                if (ordsError.errorstack > "") { print(ordsError.errorstack) }
            }
        }

        task.resume()
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

struct MMRecognizedCode: Codable {
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
    var recognizedText: [MMRecognizedText] = [MMRecognizedText]()
    var recognizedCodes: [MMRecognizedCode] = [MMRecognizedCode]()
}

//struct ScanData: Codable {
//    var images: [MMImage] = [MMImage]()
//}



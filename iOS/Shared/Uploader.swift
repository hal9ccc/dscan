//
//  Uploader.swift
//
//  dscan
//
//  from https://gist.github.com/nnsnodnb/efd4635a6be2be41fdb67135d2dd9257
//
//  Created by Matthias Schulze on 08.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import OSLog
import UIKit
import SwiftUI

typealias HTTPHeaders = [String: String]

final class Upload {

    let data:               Data
    let endpointURI:        URL
    let headers:            HTTPHeaders
    let method:             String

    // MARK: Logging

    let logger = Logger(subsystem: "de.hal9ccc.dscan", category: "network")

    
//    let number: Int
//    let boundary = "example.boundary.\(ProcessInfo.processInfo.globallyUniqueString)"
//    let fieldName = "upload_image"
    
    var parameters: Parameters? {
        return [:
//            "number": number
        ]
    }
//    var headers: HTTPHeaders {
//        return [
//            "Content-Type": "multipart/form-data; boundary=\(boundary)",
//            "Accept": "application/json"
//        ]
//    }
//

//    init(uploadData: Data) {
//        self.data = uploadData
//        self.number = number
//    }
//
    init(data:      Data,
         to:        URL,
         with:      HTTPHeaders,
         using:     String = "POST"
    ) {
        self.data               = data
//        self.endpointURI        = .init(string: to)!
        self.endpointURI        = to
        self.headers            = with
        self.method             = using
    }

    func upload(completionHandler: @escaping (UploadResult) -> Void) {

        var request = URLRequest(url: endpointURI, method: method, headers: headers)
        request.httpBody = data

        logger.debug("DataTask \(self.method) \(self.endpointURI.description)")
        logger.debug("\(self.headers.description)")

        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, urlResponse, error) in
            let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            if let data = data, case (200..<300) = statusCode {
                do {
                    let value = try Response(from: data, statusCode: statusCode)
                    completionHandler(.success(value))
                } catch {
                    let _error = ResponseError(statusCode: statusCode, error: AnyError(error))
                    completionHandler(.failure(_error))
                }
            }
            else {
                let tmpError = error ?? NSError(domain: "Unknown", code: 499, userInfo: nil)
                let _error = ResponseError(statusCode: statusCode, error: AnyError(tmpError))
                completionHandler(.failure(_error))
            }
        }
        task.resume()
    }
    
}

typealias UploadResult = Result<Response, ResponseError>

typealias Parameters = [String: Any]

struct Response {

    let statusCode: Int
    let body: Data
    let json: Parameters?
    let ordsError : OrdsError?
    
    init(from data: Data, statusCode: Int) throws {
        let decoder             = JSONDecoder()
        self.statusCode         = statusCode
        self.body               = data
        self.json               = try JSONSerialization.jsonObject(with: data, options: []) as? Parameters
        self.ordsError          = try? decoder.decode(OrdsError.self, from: data)
    }
}

struct AnyError: Error {

    let error: Error

    init(_ error: Error) {
        self.error = error
    }
}


struct ResponseError: Error {

    let statusCode: Int
    let error: AnyError
}

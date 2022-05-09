//
//  URLRequest+Init.swift
//  dscan
//
//  Created by Matthias Schulze on 08.05.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

extension URLRequest {

    init(url: URL, method: String, headers: HTTPHeaders?) {
        self.init(url: url)
        httpMethod = method

        if let headers = headers {
            headers.forEach {
                setValue($0.1, forHTTPHeaderField: $0.0)
            }
        }
    }
}

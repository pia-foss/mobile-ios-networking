//
//  NWConnectionConfiguration.swift
//
//
//  Created by Laura S on 4/10/24.
//

import Foundation

public struct NWConnectionConfiguration {

    let url: URL
    let method: NWConnectionHTTPMethod
    let headers: [String: String]?
    let certificateValidation: CertificateValidation
    let dataResponseType: NWDataResponseType
    var timeout: TimeInterval = 30
    var queue: DispatchQueue? = nil
    
    public init(url: URL, method: NWConnectionHTTPMethod, headers: [String: String]? = nil, certificateValidation: CertificateValidation, dataResponseType: NWDataResponseType, timeout: TimeInterval = 30, queue: DispatchQueue? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.certificateValidation = certificateValidation
        self.dataResponseType = dataResponseType
        self.timeout = timeout
        self.queue = queue
    }
}

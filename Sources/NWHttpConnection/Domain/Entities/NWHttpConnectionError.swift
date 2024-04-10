//
//  File.swift
//  
//
//  Created by Laura S on 4/10/24.
//

import Foundation
import Network

public enum NWHttpConnectionError: Error {
    case badURL(URL)
    case connection(NWError)
    case negitiveTimeout
    case timeoutOutOfBounds
    case receive(NWError?)
    case send(NWError)
    case wait(NWError)
    case unknown(Error)
}

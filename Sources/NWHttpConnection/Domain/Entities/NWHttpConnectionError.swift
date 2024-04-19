//
//  File.swift
//  
//
//  Created by Laura S on 4/10/24.
//

import Foundation
import Network

public enum NWHttpConnectionError: Error, Equatable {

    case badURL(URL)
    case connection(NWError)
    case negativeTimeout
    case timeoutOutOfBounds
    case receive(NWError?)
    case send(NWError)
    case wait(NWError)
    case unknown(Error)
    
    public static func == (lhs: NWHttpConnectionError, rhs: NWHttpConnectionError) -> Bool {
        switch (lhs, rhs) {
        case(.badURL(let lhsURL), .badURL(let rhsURL)):
            return lhsURL == rhsURL
        case(.connection(let lhsError), .connection(let rhsError)):
            return lhsError == rhsError
        case(.receive(let lhsError), .receive(let rhsError)):
            return lhsError == rhsError
        case(.send(let lhsError), .send(let rhsError)):
            return lhsError == rhsError
        case(.wait(let lhsError), .wait(let rhsError)):
            return lhsError == rhsError
        case(.unknown, .unknown):
            return true
        case(.timeoutOutOfBounds, .timeoutOutOfBounds):
            return true
        case(.negativeTimeout, .negativeTimeout):
            return true
        default:
            return false
        }
    }
}

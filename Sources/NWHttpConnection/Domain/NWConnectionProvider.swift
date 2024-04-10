//
//  File.swift
//  
//
//  Created by Laura S on 4/10/24.
//

import Foundation
import Network

// TODO: This probably has not to be public
protocol NWConnectionProviderType {
    func makeNWConnection(for host: NWEndpoint.Host, port: NWEndpoint.Port, params: NWParameters) -> NWConnectionType
}


class NWConnectionProvider: NWConnectionProviderType {
    
    func makeNWConnection(for host: NWEndpoint.Host, port: NWEndpoint.Port, params: NWParameters) -> NWConnectionType {
        return NWConnection(host: host, port: port, using: params)
    }
}

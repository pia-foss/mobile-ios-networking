//
//  NWHttpConnectionFactory.swift
//
//
//  Created by Laura S on 4/10/24.
//

import Foundation

public class NWHttpConnectionFactory {
    
    public static func makeNWHttpConnection(with configuration: NWConnectionConfiguration) -> NWHttpConnectionType {
        return NWHttpConnection(url: configuration.url,
                                method: configuration.method,
                                headers: configuration.headers,
                                body: configuration.body,
                                certificateValidation: configuration.certificateValidation,
                                dataResponseType: configuration.dataResponseType,
                                nwConnectionProvider: Self.makeNWConnectionProvider(),
                                timeout: configuration.timeout,
                                queue: configuration.queue)
    }
    
}


// MARK: - Private

private extension NWHttpConnectionFactory {
    static func makeNWConnectionProvider() -> NWConnectionProviderType {
        return NWConnectionProvider()
    }
}

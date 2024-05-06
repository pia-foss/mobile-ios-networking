//
//  NWHttpConnection.swift
//  PIA VPN
//
//  Created by Laura S on 3/26/24.
//  Copyright © 2024 Private Internet Access Inc. All rights reserved.
//

import Foundation
import Network
import CommonCrypto

public protocol NWHttpConnectionType {
    typealias RequestHandler = (NWHttpConnectionError?, Data?) -> Void
    typealias Completion = () -> Void
    
    func connect(requestHandler: NWHttpConnectionType.RequestHandler?, completion: NWHttpConnectionType.Completion?) throws
}

struct NWHttpConnection: NWHttpConnectionType {
    
    private let url: URL
    private let method: NWConnectionHTTPMethod
    private let headers: [String: String]?
    private let body: Data?
    private let certificateValidation: CertificateValidationType
    private let nwDataResponseType: NWDataResponseType
    private let nwConnectionProvider: NWConnectionProviderType
    private let timeout: TimeInterval
    private let queue: DispatchQueue
    
    private static let defaultQueue = DispatchQueue(label: "com.pia.nwhttpconnection", qos: .userInitiated)
    private static let deadlineTimerQueue = DispatchQueue(label: "com.pia.deadline", qos: .background)
    
    private let requiredHeaders = [
        "User-Agent": "generic/1.0",
        "Accept": "*/*",
        "Connection": "close"
    ]
    
    private let httpsPort: Int = 443
    
    init(url: URL, method: NWConnectionHTTPMethod, headers: [String: String]? = nil, body: Data?, certificateValidation: CertificateValidationType, dataResponseType: NWDataResponseType, nwConnectionProvider: NWConnectionProviderType, timeout: TimeInterval = 60, queue: DispatchQueue? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.certificateValidation = certificateValidation
        self.nwDataResponseType = dataResponseType
        self.nwConnectionProvider = nwConnectionProvider
        self.timeout = timeout
        self.queue = queue ?? Self.defaultQueue
    }
    
    func connect(requestHandler: RequestHandler? = nil, completion: Completion? = nil) throws {
        
        let (validatedHost, _) = try validate(url: url)
        let host = NWEndpoint.Host(validatedHost)
        
        let port = NWEndpoint.Port(integerLiteral: UInt16(url.port ?? httpsPort))
        
        let tcp = NWProtocolTCP.Options()
        tcp.connectionTimeout = try validate(timeout: timeout)
        
        let tls = NWProtocolTLS.Options()
        
        sec_protocol_options_set_verify_block(
            tls.securityProtocolOptions, { (metadata, trust, complete) in
                certificateValidation.validate(metadata: metadata,
                                               trust: trust,
                                               complete: complete)
            },
            self.queue
        )
        
        
        let params = NWParameters(tls: tls, tcp: tcp)
        
        var connection = nwConnectionProvider.makeNWConnection(for: host, port: port, params: params)
        let timer = deadline(connection: connection, complete: completion)
        
        receive(connection: connection,
                handle: requestHandler)
        
        connection.stateUpdateHandler = { (state) in
            self.updated(connection: connection,
                         state: state,
                         timer: timer,
                         handle: requestHandler,
                         complete: completion)
        }
        connection.start(queue: queue)
    }
    
    
}


// MARK: - Private

internal extension NWHttpConnection {
    
    func normalize(headers: [String: String]?) -> [String: String] {
        var normalized = requiredHeaders
        if let headers = headers {
            normalized = normalized.merging(headers) { _, value in value }
        }
        if let body {
            normalized["Content-Length"] = "\(body.count)"
        }
        return normalized
    }
    
    private func validate(url: URL) throws -> (host: String, scheme: String) {
        guard let scheme = url.scheme,
              let host = url.host else {
            throw NWHttpConnectionError.badURL(url)
        }
        return (host, scheme)
    }
    
    func validate(timeout: TimeInterval) throws -> Int {
        guard timeout >= 0 else { throw NWHttpConnectionError.negativeTimeout}
        if timeout >= Double(Int.max) { throw NWHttpConnectionError.timeoutOutOfBounds }
        return Int(timeout)
    }
    
    func sendConnectionRequest(connection: NWConnectionType, handle: RequestHandler?) {
        guard let validated = try? validate(url: url) else { return }
        
        let path = url.path.isEmpty ? "/" : url.path
        let query = url.query?.isEmpty ?? true ? "" : "?\(url.query!)"
        let headers = normalize(headers: headers)
        
        var content =
        "\(method.rawValue) \(path)\(query) HTTP/1.1\r\n" +
        "Host: \(validated.host)\r\n" +
        headers.map { "\($0.key): \($0.value)\r\n" }.joined() +
        "\r\n"
        
        
        if let body, let json = String(data: body, encoding: .utf8) {
            content.append(json)
        }
        
        connection.send(
            content: content.data(using: .ascii),
            contentContext: .defaultMessage,
            isComplete: true,
            completion: NWConnection.SendCompletion.contentProcessed(
                { (error) in
                    if let error = error {
                        handle?(.send(error), nil)
                        connection.cancel()
                    }
                }
            )
        )
    }
    
    func getJSONData(from data: Data) -> Data? {
        let asciiDataString = String(data: data, encoding: .ascii)
        guard let asciiDataString else { return nil }
        let containsJSON = asciiDataString.contains("Content-Type: application/json")
        guard containsJSON else { return nil }
        let jsonString = asciiDataString.split(separator: "\r\n").last
        
        guard let jsonString else { return nil }
        
        return jsonString.data(using: .utf8)
    }
    
    func receive(connection: NWConnectionType,
                 handle: RequestHandler?) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: Int(UInt16.max),
            completion: { (data, _, isComplete, error) in
                
                if let data = data {
                    switch self.nwDataResponseType {
                    case .jsonData:
                        let jsonData = getJSONData(from: data)
                        DispatchQueue.main.async {
                            handle?(nil, jsonData)
                        }
                    case .rawData:
                        DispatchQueue.main.async {
                            handle?(nil, data)
                        }
                    }
                }
                
                
                if isComplete {
                    connection.cancel()
                } else if let error = error {
                    handle?(.receive(error), nil)
                } else {
                    self.receive(connection: connection,
                                 handle: handle)
                }
            }
        )
    }
    
    func updated(connection: NWConnectionType,
                 state: NWConnection.State,
                 timer: DispatchSourceTimer,
                 handle: RequestHandler?,
                 complete: Completion?) {
        
        switch state {
        case .cancelled:
            timer.cancel()
            complete?()
        case .failed(let error):
            handle?(.connection(error), nil)
            connection.cancel()
        case .preparing:
            break
        case .ready:
            sendConnectionRequest(connection: connection, handle: handle)
        case .setup:
            break
        case .waiting(let error):
            handle?(.wait(error), nil)
            connection.cancel()
        default:
            break
        }
    }
    
    func deadline(connection: NWConnectionType,
                  complete: Completion?) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: Self.deadlineTimerQueue)
        
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler {
            connection.cancel()
        }
        timer.resume()
        return timer
    }
    
}






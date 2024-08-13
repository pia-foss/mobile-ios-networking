//
//  NWHttpConnectionLogger.swift
//  
//
//  Created by Said Rehouni on 13/8/24.
//

import Foundation
import OSLog
import Network

class NWHttpConnectionLogger {
    static func log(_ message: String) {
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "com.privateinternetaccess.networking", category: "NWHttpConnection")
            logger.info("\(message)")
        }
    }
    
    static func error(_ message: String, error: Network.NWError) {
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "com.privateinternetaccess.networking", category: "NWHttpConnection")
            logger.error("\(message)")
            logger.error("Error code: \(error.errorCode)")
            logger.error("Error description: \(error.localizedDescription) \(error.debugDescription)")
        }
    }
}

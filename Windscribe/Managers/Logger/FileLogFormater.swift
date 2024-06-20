//
//  FileLogFormater.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import CocoaLumberjack
import Foundation
class FileLogFormater: NSObject, DDLogFormatter {
    let dateFormatter: DateFormatter
    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        super.init()
    }

    func format(message logMessage: DDLogMessage) -> String? {
        let timestamp = dateFormatter.string(from: logMessage.timestamp)
        var logLevel = "debug"
        switch logMessage.level {
        case .error:
            logLevel = "error"
        case .warning:
            logLevel = "warn"
        case .info:
            logLevel = "info"
        case .verbose:
            logLevel = "verbose"
        case .all:
            logLevel = "all"
        default: ()
        }
        if let tag = logMessage.representedObject as? String {
            return "\(timestamp) [\(logLevel)] [\(tag)] - \(logMessage.message)"
        } else {
            return "\(timestamp) [\(logLevel)] - \(logMessage.message)"
        }
    }
}

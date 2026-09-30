//
//  LogModels.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

// MARK: - LogLevel

enum LogLevel: UInt8, Sendable {
    case debug = 0
    case info = 1
    case error = 2

    var stringValue: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .error: return "error"
        }
    }

    init?(stringValue: String) {
        switch stringValue.lowercased() {
        case "debug": self = .debug
        case "info": self = .info
        case "error": self = .error
        default: return nil
        }
    }
}

// MARK: - LogRetention

enum LogRetention {
    static let duration: TimeInterval = 24 * 60 * 60
    static let submissionDuration: TimeInterval = 2 * 60 * 60
}

// MARK: - LogStorageBudget

enum LogStorageBudget {
    static let maximumBytesPerProcess = 10 * 1024 * 1024
    static let maximumSegmentBytes = 1024 * 1024
}

#if DEBUG
// MARK: - DebugLogBurst

enum DebugLogBurst {
    static let maximumRecords = 1000
    static let windowDuration: TimeInterval = 1
    static let warningCooldown: TimeInterval = 60
    static let notification = Notification.Name("DebugLogBurstDetected")
    static let recordCountKey = "recordCount"
}
#endif

// MARK: - LogExportPurpose

enum LogExportPurpose: Sendable {
    case viewing
    case submission

    func duration(retentionDuration: TimeInterval) -> TimeInterval {
        switch self {
        case .viewing:
            return retentionDuration
        case .submission:
            return min(retentionDuration, LogRetention.submissionDuration)
        }
    }
}

// MARK: - LogProcess

enum LogProcess: String, CaseIterable, Sendable {
    case app
    case packetTunnel = "packet-tunnel"
    case wireGuardTunnel = "wireguard-tunnel"
    case appIntents = "app-intents"
    case siriIntents = "siri-intents"
    case homeWidget = "home-widget"
}

// MARK: - LogRecord

struct LogRecord: Equatable, Sendable {
    let timestamp: TimeInterval
    let level: LogLevel
    let module: String
    let message: String
}

// MARK: - LogSegment

struct LogSegment: Equatable, Sendable {
    let process: LogProcess
    let bucketStart: TimeInterval
    let sequence: UInt32
    let url: URL
}

// MARK: - LogExportArtifact

struct LogExportArtifact: Sendable {
    let url: URL
    let contentType: String
}

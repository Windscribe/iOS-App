//
//  FileLoggerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation
import RxSwift

class FileLoggerImpl: FileLogger {
    private let maxLogLength = 120_000

    // MARK: - Throttling Configuration (Errors Always Logged)
    private let throttleInterval: TimeInterval = 0.2 // 200ms minimum between identical non-error logs
    private let maxNonErrorLogsPerSecond: Int = 40 // Limit debug/info logs to 40 per second
    private let burstAllowance: Int = 5 // Allow burst of 5 non-error logs before throttling

    // MARK: - Throttling State
    private let throttleQueue = DispatchQueue(label: "com.windscribe.logging.throttle", qos: .utility)
    private var messageThrottleMap: [String: TimeInterval] = [:]
    private var nonErrorLogTimestamps: [TimeInterval] = []
    private var currentBurstCount: Int = 0
    private var lastBurstReset: TimeInterval = 0
    var logDirectory: URL? = {
        let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedKeys.sharedGroup)
        #if os(tvOS)
            return containerUrl?.appendingPathComponent("Library/Caches")
        #else
            return containerUrl?.appendingPathComponent("AppExtensionLogs")
        #endif
    }()

    init() {
        setupLogger()
    }

    func logD(_ tag: Any, _ message: String) {
//        #if DEBUG
        logWithThrottling(.debug, tag: tag, message: message)
//        #endif
    }

    func logI(_ tag: Any, _ message: String) {
        logWithThrottling(.info, tag: tag, message: message)
    }

    func logE(_ tag: Any, _ message: String) {
        // ERRORS ARE ALWAYS LOGGED - NO THROTTLING
        DDLogError(DDLogMessageFormat("\(message)"), level: DDLogLevel.error, tag: tag)
    }

    // MARK: - Throttling Implementation (Debug/Info Only)

    private enum LogLevel {
        case debug, info, error
    }

    private func logWithThrottling(_ level: LogLevel, tag: Any, message: String) {
        throttleQueue.async { [weak self] in
            guard let self = self else { return }

            let now = Date().timeIntervalSince1970
            let messageHash = "\(tag)-\(message)".hash
            let messageKey = String(messageHash)

            // Check if we should throttle this specific message
            if let lastLogTime = self.messageThrottleMap[messageKey],
               now - lastLogTime < self.throttleInterval {
                return // Skip this log due to message throttling
            }

            // Check rate limiting for non-error logs
            if !self.shouldAllowNonErrorLog(at: now) {
                return // Skip this log due to rate limiting
            }

            // Update throttling state
            self.messageThrottleMap[messageKey] = now
            self.recordNonErrorLogTimestamp(now)

            // Clean up old entries periodically
            if self.messageThrottleMap.count > 500 {
                self.cleanupThrottleMap(currentTime: now)
            }

            // Perform actual logging on main queue
            DispatchQueue.main.async {
                switch level {
                case .debug:
                    DDLogDebug(DDLogMessageFormat("\(message)"), level: DDLogLevel.debug, tag: tag)
                case .info:
                    DDLogInfo(DDLogMessageFormat("\(message)"), level: DDLogLevel.info, tag: tag)
                case .error:
                    // This should never be called since errors bypass throttling
                    DDLogError(DDLogMessageFormat("\(message)"), level: DDLogLevel.error, tag: tag)
                }
            }
        }
    }

    private func shouldAllowNonErrorLog(at timestamp: TimeInterval) -> Bool {
        // Remove timestamps older than 1 second
        nonErrorLogTimestamps.removeAll { timestamp - $0 > 1.0 }

        // Check burst allowance
        if timestamp - lastBurstReset > 1.0 {
            // Reset burst counter every second
            currentBurstCount = 0
            lastBurstReset = timestamp
        }

        // Allow bursts up to the limit
        if currentBurstCount < burstAllowance {
            currentBurstCount += 1
            return true
        }

        // Check rate limit for sustained logging
        if nonErrorLogTimestamps.count < maxNonErrorLogsPerSecond {
            return true
        }

        return false
    }

    private func recordNonErrorLogTimestamp(_ timestamp: TimeInterval) {
        nonErrorLogTimestamps.append(timestamp)

        // Keep only recent timestamps to prevent memory growth
        if nonErrorLogTimestamps.count > maxNonErrorLogsPerSecond * 2 {
            nonErrorLogTimestamps.removeFirst(nonErrorLogTimestamps.count - maxNonErrorLogsPerSecond)
        }
    }

    private func cleanupThrottleMap(currentTime: TimeInterval) {
        messageThrottleMap = messageThrottleMap.filter { _, lastLogTime in
            currentTime - lastLogTime < 30.0 // Keep entries for 30 seconds
        }
    }

    func getLogData() -> Single<String> {
        return Single.create { [weak self] callback in
            guard let self = self else {
                return Disposables.create {}
            }
            var allLogEntries: [String] = []
            let allLogFiles = self.getAllLogFiles()

            for logFileURL in allLogFiles {
                do {
                    let logContent = try String(contentsOf: logFileURL)
                    allLogEntries.append(contentsOf: buildLogEntries(from: logContent))
                } catch {
                    print("Error reading log file: \(error)")
                }
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

            // Assuming log entries have timestamps at the beginning, sort them based on timestamps.
            let sortedLogEntries = allLogEntries
                .compactMap { entry -> (Date, String)? in
                    let components = entry.components(separatedBy: " ")
                    guard components.count >= 2 else {
                        return nil
                    }
                    if let timestamp = dateFormatter.date(from: "\(components[0]) \(components[1])"),
                       let jsonEntry = self.logEntryToJSON(entry) {
                        return (timestamp, jsonEntry)
                    }
                    return nil
                }
                .sorted { $0.0.compare($1.0) == .orderedAscending }
                .map { $0.1 }
            let combinedLog = sortedLogEntries.joined(separator: "")
            let truncatedLog: String
            if combinedLog.count > maxLogLength {
                let startIndex = combinedLog.index(combinedLog.endIndex, offsetBy: -maxLogLength)
                let substring = combinedLog[startIndex...]
                if let firstNewlineIndex = substring.firstIndex(of: "\n") {
                    truncatedLog = String(substring[firstNewlineIndex...])
                } else {
                    truncatedLog = String(substring)
                }
            } else {
                truncatedLog = combinedLog
            }
            callback(.success(truncatedLog))
            return Disposables.create {}
        }
    }

    private func logEntryToJSON(_ logEntry: String) -> String? {
        let values = logEntry.split(separator: " ")
        guard values.count >= 5 else { return nil }
        var message = Array(values[5..<values.endIndex]).reduce("") { result, value in
            let middle = result.isEmpty ? result : " "
            return result + middle + String(value)
        }

        guard !message.isEmpty else { return nil }

        if !message.contains("DeviceInfo") {
            message.removeLast()
        }

        let lvl = removeBrackets(String(values[2]))
        let mod = removeBrackets(String(values[3]))

        return "{\"tm\": \"\(values[0]) \(values[1])\"," +
        " \"lvl\": \"\(lvl)\"," +
        " \"mod\": \"\(mod)\"," +
        " \"msg\": \"\(message)\"}\n"
    }

    private func removeBrackets(_ input: String) -> String {
        return input.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
    }

    func logDeviceInfo() {
        let currentDevice = UIDevice.current
        let deviceInfo = [
            "\n[DeviceInfo]",
            "-------------",
            "[Device]: \(currentDevice.model)",
            "[OS Version]: \(currentDevice.systemVersion)",
            "[Release]: \(Bundle.main.buildVersionNumber ?? "")",
            "[App Release Version]: \(Bundle.main.releaseVersionNumber ?? "")",
            "[Start of log]:",
            "------------------------------------------------------"
        ]
        let fullInfo = deviceInfo.joined(separator: "\n")
        logD(self, fullInfo)
    }

    private func setupLogger() {
        let logFileManager = DDLogFileManagerDefault(logsDirectory: logDirectory?.path)
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = 0
        fileLogger.maximumFileSize = 2_000_000
        fileLogger.logFileManager.maximumNumberOfLogFiles = 1
        fileLogger.logFormatter = FileLogFormater()
        if DDLog.allLoggers.count == 0 {
            DDLog.add(fileLogger)
            let osLogger = DDOSLogger(subsystem: "com.windscribe.vpn", category: "Windscribe-VPN")
            osLogger.logFormatter = FileLogFormater()
            DDLog.add(osLogger)

            // Log throttling configuration on startup
            DDLogInfo(DDLogMessageFormat("Logging throttling enabled: Max \(maxNonErrorLogsPerSecond) non-error logs/sec, \(throttleInterval)s duplicate message interval. Errors are never throttled."), level: DDLogLevel.info, tag: self)
        }
    }

    private func getAllLogFiles() -> [URL] {
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: logDirectory!.path).map { fileName in
                logDirectory?.appendingPathComponent(fileName)
            }.compactMap { $0 }
            return fileNames
        } catch {
            return []
        }
    }

    private func buildLogEntries(from fileContent: String) -> [String] {
        var logEntries: [String] = []
        var currentLogEntry = ""
        let regexPattern = #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}"#
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let lines = fileContent.components(separatedBy: .newlines)

            for line in lines {
                let range = NSRange(location: 0, length: line.utf16.count)
                if let match = regex.firstMatch(in: line, options: [], range: range), let timestampRange = Range(match.range, in: line) {
                    _ = String(line[timestampRange])
                    if !currentLogEntry.isEmpty {
                        logEntries.append(currentLogEntry)
                        currentLogEntry = ""
                    }
                }
                currentLogEntry += line + "\n"
            }
            if !currentLogEntry.isEmpty {
                logEntries.append(currentLogEntry)
            }
        } catch {}
        return logEntries
    }
}

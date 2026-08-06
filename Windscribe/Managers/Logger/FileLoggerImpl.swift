//
//  FileLoggerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import os.log

enum LogLevel: String {
    case debug, info, error
}

private extension CodingUserInfoKey {
    static let logDateFormatter = CodingUserInfoKey(rawValue: "logDateFormatter")!
}

private struct LogBufferModel: Codable {
    enum CodingKeys: String, CodingKey {
        case level = "lvl"
        case tag = "mod"
        case message = "msg"
        case timestamp = "tm"
    }

    let level: LogLevel
    let tag: String
    let message: String
    let timestamp: TimeInterval
    let timestampString: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode in specific order: tm, lvl, mod, msg for human readability
        try container.encode(timestampString, forKey: .timestamp)
        try container.encode(level.rawValue, forKey: .level)
        try container.encode(tag, forKey: .tag)
        try container.encode(message, forKey: .message)
    }

    private func escapeJSONString(_ input: String) -> String {
        var result = ""
        for char in input {
            switch char {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(char)
            }
        }
        return result
    }

    func toOrderedJSONString() -> String {
        // Prevent multiple replacingOccurrences
        let escapedTag = escapeJSONString(tag)
        let escapedMessage = escapeJSONString(message)

        return "{\"tm\": \"\(timestampString)\", \"lvl\": \"\(level.rawValue)\", \"mod\": \"\(escapedTag)\", \"msg\": \"\(escapedMessage)\"}"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode tag and message directly
        tag = try container.decode(String.self, forKey: .tag)
        message = try container.decode(String.self, forKey: .message)

        // Decode level string and convert to enum
        let levelString = try container.decode(String.self, forKey: .level)
        switch levelString {
        case "debug": level = .debug
        case "info": level = .info
        case "error": level = .error
        default: level = .info // fallback
        }

        guard let dateFormatter = decoder.userInfo[.logDateFormatter] as? DateFormatter else {
            throw DecodingError.dataCorruptedError(
                forKey: .timestamp,
                in: container,
                debugDescription: "Missing log date formatter."
            )
        }

        let decodedTimestampString = try container.decode(String.self, forKey: .timestamp)
        if let date = dateFormatter.date(from: decodedTimestampString) {
            timestamp = date.timeIntervalSince1970
            timestampString = decodedTimestampString
        } else {
            let now = Date()
            timestamp = now.timeIntervalSince1970
            timestampString = dateFormatter.string(from: now)
        }
    }

    init(level: LogLevel, tag: String, message: String, timestamp: TimeInterval, dateFormatter: DateFormatter) {
        self.level = level
        self.tag = tag
        self.message = message
        self.timestamp = timestamp
        timestampString = dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
}

class FileLoggerImpl: FileLogger {

    private let maxLogLength = 120_000
    private let logFileName = "windscribe.log"
    private let logSchemaVersion = 1
    private let jsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    // MARK: - Log Batching Configuration
    private let batchFlushInterval: TimeInterval = 10.0 // Flush every 10 seconds
    private let batchMaxSize: Int = 50 // Flush when buffer reaches 50 logs
    private let batchMaxMemorySize: Int = 10_000 // Flush when buffer reaches ~10KB of text

    // MARK: - Log Retention Configuration
    private let maxLogRetentionHours: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
    private let maxLogFileSize: Int = 2 * 1024 * 1024 // 2MB total
    private let logCompactionInterval: TimeInterval = 60 * 60

    // MARK: - Batching State
    private let batchQueue = DispatchQueue(label: "com.windscribe.logging.batch", qos: .utility)
    private var logBuffer: [LogBufferModel] = []
    private var batchTimer: DispatchSourceTimer?
    private var currentBufferSize: Int = 0
    private var lastCompactionTime = Date().timeIntervalSince1970
    var logDirectory: URL? = {
        let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedKeys.sharedGroup)
        let subpath = Env.isTVOS ? "Library/Caches" : "AppExtensionLogs"
        return containerUrl?.appendingPathComponent(subpath)
    }()

    init() {
        setupLogger()
        startBatchTimer()
    }

    func logD(_ tag: String, _ message: String) {
        logD(tag, message, flushImmediately: false)
    }

    func logD(_ tag: String, _ message: String, flushImmediately: Bool) {
        #if DEBUG
        addToBatch(.debug, tag: tag, message: message, flushImmediately: flushImmediately)
        #endif
    }

    func logI(_ tag: String, _ message: String) {
        logI(tag, message, flushImmediately: false)
    }

    func logI(_ tag: String, _ message: String, flushImmediately: Bool) {
        addToBatch(.info, tag: tag, message: message, flushImmediately: flushImmediately)
    }

    func logWSNet(_ message: String) {
        batchQueue.async { [weak self] in
            guard let self else { return }

            let logEntry: LogBufferModel
            if let jsonData = message.data(using: .utf8),
               let wsnetLog = try? self.makeLogDecoder().decode(LogBufferModel.self, from: jsonData) {
                logEntry = wsnetLog
            } else {
                logEntry = LogBufferModel(
                    level: .info,
                    tag: "wsnet",
                    message: message,
                    timestamp: Date().timeIntervalSince1970,
                    dateFormatter: self.jsonDateFormatter
                )
            }
            self.addLogBufferModelToBatch(logEntry, flushImmediately: false)
        }
    }

    func logE(_ tag: String, _ message: String) {
        logE(tag, message, flushImmediately: false)
    }

    func logE(_ tag: String, _ message: String, flushImmediately: Bool) {
        addToBatch(.error, tag: tag, message: message, flushImmediately: flushImmediately)
    }

    // MARK: - Log Batching Implementation

    private func getLogFileURL() -> URL? {
        guard let logDirectory = logDirectory else {
            return nil
        }
        return logDirectory.appendingPathComponent(logFileName)
    }

    private func addToBatch(_ level: LogLevel, tag: String, message: String, flushImmediately: Bool) {
        batchQueue.async { [weak self] in
            guard let self else { return }
            let logEntry = LogBufferModel(
                level: level,
                tag: tag,
                message: message,
                timestamp: Date().timeIntervalSince1970,
                dateFormatter: self.jsonDateFormatter
            )
            self.addLogBufferModelToBatch(logEntry, flushImmediately: flushImmediately)
        }
    }

    private func addLogBufferModelToBatch(_ logEntry: LogBufferModel, flushImmediately: Bool) {
#if DEBUG
        print(logEntry.toOrderedJSONString())
#endif
        logBuffer.append(logEntry)
        currentBufferSize += logEntry.message.count + "\(logEntry.tag)".count

        // Check if we should flush the buffer
        if flushImmediately ||
           logBuffer.count >= batchMaxSize ||
           currentBufferSize >= batchMaxMemorySize {
            flushLogBuffer()
        }
    }

    private func startBatchTimer() {
        let timer = DispatchSource.makeTimerSource(queue: batchQueue)
        timer.schedule(deadline: .now() + batchFlushInterval, repeating: batchFlushInterval)
        timer.setEventHandler { [weak self] in
            self?.flushLogBuffer()
        }
        timer.resume()
        self.batchTimer = timer
    }

    private func flushLogBuffer(completion: (() -> Void)? = nil) {
        batchQueue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            guard !self.logBuffer.isEmpty else {
                completion?()
                return
            }

            let bufferCopy = self.logBuffer
            self.logBuffer.removeAll()
            self.currentBufferSize = 0

            // Sort by timestamp to maintain chronological order
            let sortedLogs = bufferCopy.sorted { $0.timestamp < $1.timestamp }

            // Convert to JSON and write to file
            self.writeLogsToFile(sortedLogs)
            completion?()
        }
    }

    private func writeLogsToFile(_ logs: [LogBufferModel]) {
        guard let logFileURL = getLogFileURL() else {
            return
        }
        guard !logs.isEmpty else { return }

        do {
            let jsonLines = logs.map { log in
                log.toOrderedJSONString()
            }
            let content = jsonLines.joined(separator: "\n") + "\n"

            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(Data(content.utf8))
                fileHandle.closeFile()
            } else {
                try content.write(to: logFileURL, atomically: true, encoding: .utf8)
            }

            let now = Date().timeIntervalSince1970
            let fileSize = try logFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            if fileSize > maxLogFileSize || now - lastCompactionTime >= logCompactionInterval {
                compactLogFile()
            }
        } catch {
            // Silently fail - logging errors in the logger creates infinite loops
        }
    }

    private func compactLogFile() {
        guard let logFileURL = getLogFileURL(),
              FileManager.default.fileExists(atPath: logFileURL.path) else {
            lastCompactionTime = Date().timeIntervalSince1970
            return
        }

        let trimmedLogs = applyRetentionPolicies(logs: parseExistingLogFile(logFileURL: logFileURL))
        let jsonLines = trimmedLogs.map { $0.toOrderedJSONString() }
        let content = jsonLines.joined(separator: "\n") + (jsonLines.isEmpty ? "" : "\n")

        do {
            try content.write(to: logFileURL, atomically: true, encoding: .utf8)
            lastCompactionTime = Date().timeIntervalSince1970
        } catch {
            // Silently fail - logging errors in the logger creates infinite loops
        }
    }

    private func parseExistingLogFile(logFileURL: URL) -> [LogBufferModel] {
        do {
            let content = try String(contentsOf: logFileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            let decoder = makeLogDecoder()
            var parsedLogs: [LogBufferModel] = []

            for line in lines {
                if let data = line.data(using: .utf8) {
                    do {
                        let logEntry = try decoder.decode(LogBufferModel.self, from: data)
                        parsedLogs.append(logEntry)
                    } catch {
                        // Silently skip malformed log lines
                    }
                }
            }

            return parsedLogs
        } catch {
            return []
        }
    }

    private func applyRetentionPolicies(logs: [LogBufferModel]) -> [LogBufferModel] {
        let now = Date().timeIntervalSince1970
        let cutoffTime = now - maxLogRetentionHours

        // Step 1: Remove logs older than 24 hours
        let recentLogs = logs.filter { $0.timestamp >= cutoffTime }

        // Step 2: If still over size limit, remove oldest entries
        let sortedLogs = recentLogs.sorted { $0.timestamp < $1.timestamp }

        // Calculate current size using ordered JSON strings
        var currentSize = 0
        var finalLogs: [LogBufferModel] = []

        // Start from newest and work backwards to keep as much recent data as possible
        for log in sortedLogs.reversed() {
            let jsonString = log.toOrderedJSONString()
            let logSize = jsonString.utf8.count + 1 // +1 for newline

            if currentSize + logSize <= maxLogFileSize {
                finalLogs.insert(log, at: 0) // Insert at beginning to maintain chronological order
                currentSize += logSize
            } else {
                break // Stop adding logs once we hit the size limit
            }
        }

        return finalLogs
    }

    deinit {
        batchTimer?.cancel()
        flushLogBuffer() // Ensure any remaining logs are written
    }

    func getLogData() async throws -> String {
        return await withCheckedContinuation { continuation in
            guard let logFileURL = getLogFileURL() else {
                continuation.resume(returning: "")
                return
            }

            flushLogBuffer { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: "")
                    return
                }

                let allLogs = self.parseExistingLogFile(logFileURL: logFileURL)
                let sortedLogs = allLogs.sorted { $0.timestamp > $1.timestamp }
                let metadata = self.makeLogMetadata()
                let availableLogLength = max(0, self.maxLogLength - metadata.count - 1)
                let combinedLog = sortedLogs
                    .reduce(into: "", {
                        let log = $1.toOrderedJSONString()
                        if $0.count + log.count + "\n".count <= availableLogLength {
                            return $0 = log + "\n" + $0
                        }
                    })
                continuation.resume(returning: combinedLog + metadata + "\n")
            }
        }
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
        logD("FileLogger", fullInfo)
    }

    private func makeLogMetadata() -> String {
        let timestamp = Date().timeIntervalSince1970
        return LogBufferModel(
            level: .info,
            tag: "LogMetadata",
            message: "schema_version=\(logSchemaVersion) app_version=\(Bundle.main.releaseVersionNumber ?? "unknown") app_build=\(Bundle.main.buildVersionNumber ?? "unknown") os_version=\(UIDevice.current.systemVersion)",
            timestamp: timestamp,
            dateFormatter: jsonDateFormatter
        ).toOrderedJSONString()
    }

    private func makeLogDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.logDateFormatter] = jsonDateFormatter
        return decoder
    }

    private func setupLogger() {
        // Ensure log directory exists
        guard let logDirectory = logDirectory else { return }

        do {
            try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // Silently fail - logging errors in the logger creates infinite loops
        }

        // Log configuration on startup to the JSON log file
        let retentionHours = Int(maxLogRetentionHours / (60 * 60))
        let maxSizeMB = maxLogFileSize / (1024 * 1024)
        let startupMessage = "JSON log retention: \(retentionHours)h time limit, \(maxSizeMB)MB size limit. Batching: \(batchMaxSize) logs/batch, \(batchFlushInterval)s interval."
        addToBatch(.info, tag: "FileLogger", message: startupMessage, flushImmediately: false)
    }
}

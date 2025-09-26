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

class FileLoggerImpl: FileLogger {
    enum LogLevel: String {
        case debug, info, error
    }

    private struct LogBufferModel: Codable {
        enum CodingKeys: String, CodingKey {
            case level = "lvl"
            case tag = "mod"
            case message = "msg"
            case timestamp = "tm"
        }

        private static let jsonDateFormatter: DateFormatter = {
              let formatter = DateFormatter()
              formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
              return formatter
          }()

        let level: LogLevel
        let tag: String
        let message: String
        let timestamp: TimeInterval

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            let formattedTime = LogBufferModel.jsonDateFormatter.string(from: Date(timeIntervalSince1970: timestamp))

            // Encode in specific order: tm, lvl, mod, msg for human readability
            try container.encode(formattedTime, forKey: .timestamp)
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
              let formattedTime = Self.jsonDateFormatter.string(from: Date(timeIntervalSince1970: timestamp))

              // Prevent multiple replacingOccurrences
              let escapedTag = escapeJSONString(tag)
              let escapedMessage = escapeJSONString(message)

              return "{\"tm\": \"\(formattedTime)\", \"lvl\": \"\(level.rawValue)\", \"mod\": \"\(escapedTag)\", \"msg\": \"\(escapedMessage)\"}"
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

            // Decode timestamp string and convert to TimeInterval
            let timestampString = try container.decode(String.self, forKey: .timestamp)
            timestamp = LogBufferModel.jsonDateFormatter.date(from: timestampString)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        }

        // Keep the original init for creating new log entries
        init(level: LogLevel, tag: String, message: String) {
            self.level = level
            self.tag = tag
            self.message = message
            self.timestamp = Date().timeIntervalSince1970
        }
    }

    private let maxLogLength = 120_000
    private let logFileName = "windscribe.log"

    // MARK: - Log Batching Configuration
    private let batchFlushInterval: TimeInterval = 10.0 // Flush every 10 seconds
    private let batchMaxSize: Int = 50 // Flush when buffer reaches 50 logs
    private let batchMaxMemorySize: Int = 10_000 // Flush when buffer reaches ~10KB of text

    // MARK: - Log Retention Configuration
    private let maxLogRetentionHours: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
    private let maxLogFileSize: Int = 2 * 1024 * 1024 // 2MB total

    // MARK: - Batching State
    private let batchQueue = DispatchQueue(label: "com.windscribe.logging.batch", qos: .utility)
    private var logBuffer: [LogBufferModel] = []
    private var batchTimer: Timer?
    private var currentBufferSize: Int = 0
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
        startBatchTimer()
    }

    func logD(_ tag: String, _ message: String) {
        #if DEVELOPMENT
        addToBatch(.debug, tag: tag, message: message)
        #endif
    }

    func logI(_ tag: String, _ message: String) {
        addToBatch(.info, tag: tag, message: message)
    }

    func logWSNet(_ message: String) {
        guard let jsonData = message.data(using: .utf8),
        let wsnetLog = try? JSONDecoder().decode(LogBufferModel.self, from: jsonData)
        else {
            addToBatch(.info, tag: "wsnet", message: message)
            return
        }
        addLogBufferModelToBatch(wsnetLog)
    }

    func logE(_ tag: String, _ message: String) {
        addToBatch(.error, tag: tag, message: message)
    }

    // MARK: - Log Batching Implementation

    private func getLogFileURL() -> URL? {
        guard let logDirectory = logDirectory else {
            return nil
        }
        return logDirectory.appendingPathComponent(logFileName)
    }

    private func addToBatch(_ level: LogLevel, tag: String, message: String) {
        let logEntry = LogBufferModel(level: level, tag: tag, message: message)
        addLogBufferModelToBatch(logEntry)
    }

    private func addLogBufferModelToBatch(_ logEntry: LogBufferModel) {
#if DEVELOPMENT
        print(logEntry.toOrderedJSONString())
#endif
        batchQueue.async { [weak self] in
            guard let self = self else { return }
            self.logBuffer.append(logEntry)
            self.currentBufferSize += logEntry.message.count + "\(logEntry.tag)".count

            // Check if we should flush the buffer
            if self.logBuffer.count >= self.batchMaxSize ||
               self.currentBufferSize >= self.batchMaxMemorySize {
                self.flushLogBuffer()
            }
        }
    }

    private func startBatchTimer() {
        self.batchTimer = Timer.scheduledTimer(withTimeInterval: self.batchFlushInterval, repeats: true) { [weak self] _ in
            self?.flushLogBuffer()
        }
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
        guard let logFileURL = getLogFileURL() else { return }
        guard !logs.isEmpty else { return }

        do {
            // Read existing logs and combine with new ones
            var allLogs: [LogBufferModel] = []

            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let existingLogs = parseExistingLogFile(logFileURL: logFileURL)
                allLogs.append(contentsOf: existingLogs)
            }

            // Add new logs
            allLogs.append(contentsOf: logs)

            // Apply retention policies
            let trimmedLogs = applyRetentionPolicies(logs: allLogs)

            // Write trimmed logs back to file using custom ordered JSON
            let trimmedJsonLines = trimmedLogs.map { log in
                log.toOrderedJSONString()
            }

            let finalContent = trimmedJsonLines.joined(separator: "\n") + (trimmedJsonLines.isEmpty ? "" : "\n")
            try finalContent.write(to: logFileURL, atomically: true, encoding: .utf8)

        } catch {
            os_log("Failed to write logs to file: %{public}@", log: OSLog(subsystem: "com.windscribe", category: "FileLogger"), type: .error, error.localizedDescription)
        }
    }

    private func parseExistingLogFile(logFileURL: URL) -> [LogBufferModel] {
        do {
            let content = try String(contentsOf: logFileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            let decoder = JSONDecoder()
            var parsedLogs: [LogBufferModel] = []

            for line in lines {
                if let data = line.data(using: .utf8) {
                    do {
                        let logEntry = try decoder.decode(LogBufferModel.self, from: data)
                        parsedLogs.append(logEntry)
                    } catch {
                        os_log("Failed to parse log line - Error: %{public}@", log: OSLog(subsystem: "com.windscribe", category: "FileLogger"), type: .error, error.localizedDescription)
                    }
                }
            }

            return parsedLogs
        } catch {
            os_log("Failed to read existing log file: %{public}@", log: OSLog(subsystem: "com.windscribe", category: "FileLogger"), type: .error, error.localizedDescription)
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
            let logSize = jsonString.count + 1 // +1 for newline

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
        batchTimer?.invalidate()
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
                let combinedLog = sortedLogs
                    .reduce(into: "", {
                        let log = $1.toOrderedJSONString()
                        if $0.count + log.count + "\n".count <= self.maxLogLength {
                            return $0 = log + "\n" + $0
                        }
                    })
                continuation.resume(returning: combinedLog)
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

    private func setupLogger() {
        // Ensure log directory exists
        guard let logDirectory = logDirectory else { return }

        do {
            try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            os_log("Failed to create log directory: %{public}@", log: OSLog(subsystem: "com.windscribe", category: "FileLogger"), type: .error, error.localizedDescription)
        }

        // Log configuration on startup to the JSON log file
        let retentionHours = Int(maxLogRetentionHours / (60 * 60))
        let maxSizeMB = maxLogFileSize / (1024 * 1024)
        let startupMessage = "JSON log retention: \(retentionHours)h time limit, \(maxSizeMB)MB size limit. Batching: \(batchMaxSize) logs/batch, \(batchFlushInterval)s interval."
        addToBatch(.info, tag: "FileLogger", message: startupMessage)
    }


}

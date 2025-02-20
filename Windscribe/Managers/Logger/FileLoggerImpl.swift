//
//  FileLoggerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import CocoaLumberjack
import Foundation
import RxSwift

class FileLoggerImpl: FileLogger {
    private let maxLogLength = 120_000
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
        DDLogDebug(DDLogMessageFormat("\(message)"), level: DDLogLevel.debug, tag: tag)
    }

    func logI(_ tag: Any, _ message: String) {
        DDLogInfo(DDLogMessageFormat("\(message)"), level: DDLogLevel.info, tag: tag)
    }

    func logE(_ tag: Any, _ message: String) {
        DDLogError(DDLogMessageFormat("\(message)"), level: DDLogLevel.error, tag: tag)
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
                    if let timestamp = dateFormatter.date(from: "\(components[0]) \(components[1])") {
                        return (timestamp, entry)
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
        logD(self, deviceInfo.joined(separator: "\n"))
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
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

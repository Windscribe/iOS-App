//
//  FileLoggerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

private struct AppLogMetadataProvider: LogMetadataProviding, Sendable {
    let schemaVersion: Int
    let appVersion: String
    let appBuild: String
    let osVersion: String

    func metadataRecord(at timestamp: TimeInterval) -> LogRecord {
        LogRecord(
            timestamp: timestamp,
            level: .info,
            module: "LogMetadata",
            message: "schema_version=\(schemaVersion) " +
                "app_version=\(appVersion) " +
                "app_build=\(appBuild) " +
                "os_version=\(osVersion)"
        )
    }
}

private struct WSNetLibraryLogPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case level = "lvl"
        case module = "mod"
        case message = "msg"
        case timestamp = "tm"
    }

    let level: String
    let module: String
    let message: String
    let timestamp: String
}

final class FileLoggerImpl: FileLogger, @unchecked Sendable {
    // MARK: - Properties

    let logDirectory: URL?

    private let wsNetDateFormatterLock = NSLock()
    private let now: @Sendable () -> TimeInterval
    private let wsNetDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private var writer: SegmentedLogWriter?
    private var exporter: JSONLogExporter?

    // MARK: - Initializer

    init(
        logDirectory: URL? = nil,
        process: LogProcess = .app,
        retentionDuration: TimeInterval = LogRetention.duration,
        maximumSegmentBytes: Int = LogStorageBudget.maximumSegmentBytes,
        maximumStoredBytes: Int = LogStorageBudget.maximumBytesPerProcess,
        now: @escaping @Sendable () -> TimeInterval = {
            Date().timeIntervalSince1970
        }
    ) {
        let directory = logDirectory ?? Self.defaultLogDirectory()
        self.logDirectory = directory
        self.now = now
        initComponents(
            directory: directory,
            process: process,
            retentionDuration: retentionDuration,
            maximumSegmentBytes: maximumSegmentBytes,
            maximumStoredBytes: maximumStoredBytes,
            now: now
        )
        writer?.log(
            .info,
            module: "FileLogger",
            message: "Segmented logger started. Batching: 50 records, 10s interval."
        )
    }

    // MARK: - FileLogger

    func logD(_ tag: String, _ message: String) {
        logD(tag, message, flushImmediately: false)
    }

    func logD(_ tag: String, _ message: String, flushImmediately: Bool) {
#if DEBUG
        writer?.log(
            .debug,
            module: tag,
            message: message,
            flushImmediately: flushImmediately
        )
#endif
    }

    func logI(_ tag: String, _ message: String) {
        logI(tag, message, flushImmediately: false)
    }

    func logI(_ tag: String, _ message: String, flushImmediately: Bool) {
        writer?.log(
            .info,
            module: tag,
            message: message,
            flushImmediately: flushImmediately
        )
    }

    func logE(_ tag: String, _ message: String) {
        logE(tag, message, flushImmediately: false)
    }

    func logE(_ tag: String, _ message: String, flushImmediately: Bool) {
        writer?.log(
            .error,
            module: tag,
            message: message,
            flushImmediately: flushImmediately
        )
    }

    func logWSNet(_ message: String) {
        let record = makeWSNetRecord(message)
#if !DEBUG
        guard record.level != .debug else { return }
#endif
        writer?.log(record)
    }

    func getLogData() async throws -> String {
        try await getLogData(for: .viewing)
    }

    func getLogData(for purpose: LogExportPurpose) async throws -> String {
        guard let writer, let exporter else { return "" }

        await writer.flush()
        let artifact = try await exporter.exportLogs(for: purpose)
        defer { try? FileManager.default.removeItem(at: artifact.url) }
        return try String(contentsOf: artifact.url, encoding: .utf8)
    }

    func logDeviceInfo() {
        let currentDevice = UIDevice.current
        let deviceInfo = [
            "[DeviceInfo] [Device]: \(currentDevice.model)",
            "[OS Version]: \(currentDevice.systemVersion) " +
                "[Release]: \(Bundle.main.buildVersionNumber ?? "") " +
                "[App Release Version]: \(Bundle.main.releaseVersionNumber ?? "")"
        ]
        logD("FileLogger", deviceInfo.joined(separator: "\n"))
    }

    // MARK: - Private Methods

    private func initComponents(
        directory: URL?,
        process: LogProcess,
        retentionDuration: TimeInterval,
        maximumSegmentBytes: Int,
        maximumStoredBytes: Int,
        now: @escaping @Sendable () -> TimeInterval
    ) {
        guard let directory else { return }

        _ = try? LegacyLogArchive.archive(in: directory, at: now())

        let codec = BinaryLogRecordCodec()
        let segmentWriter = FileLogSegmentWriter(
            baseURL: directory,
            process: process
        )
        let segmentedWriter = SegmentedLogWriter(
            now: now,
            codec: codec,
            segments: segmentWriter,
            retentionDuration: retentionDuration,
            maximumSegmentBytes: maximumSegmentBytes,
            maximumStoredBytes: maximumStoredBytes
        )
#if DEBUG && os(iOS)
        if process == .app {
            segmentedWriter.setBurstWarningHandler { recordCount in
                NotificationCenter.default.post(
                    name: DebugLogBurst.notification,
                    object: nil,
                    userInfo: [DebugLogBurst.recordCountKey: recordCount]
                )
            }
        }
#endif
        writer = segmentedWriter
        let segmentReader = FileLogSegmentReader(baseURL: directory)
        let metadata = AppLogMetadataProvider(
            schemaVersion: 1,
            appVersion: Bundle.main.releaseVersionNumber ?? "unknown",
            appBuild: Bundle.main.buildVersionNumber ?? "unknown",
            osVersion: UIDevice.current.systemVersion
        )
        exporter = JSONLogExporter(
            now: now,
            segments: segmentReader,
            codec: codec,
            metadata: metadata,
            exportDirectory: directory,
            retentionDuration: retentionDuration
        )
    }

    private func makeWSNetRecord(_ message: String) -> LogRecord {
        guard let data = message.data(using: .utf8),
              let payload = try? JSONDecoder().decode(
                WSNetLibraryLogPayload.self,
                from: data
              ) else {
            return LogRecord(
                timestamp: now(),
                level: .info,
                module: "wsnet",
                message: message
            )
        }

        wsNetDateFormatterLock.lock()
        let timestamp = wsNetDateFormatter.date(from: payload.timestamp)?.timeIntervalSince1970
        wsNetDateFormatterLock.unlock()

        return LogRecord(
            timestamp: timestamp ?? now(),
            level: LogLevel(stringValue: payload.level) ?? .info,
            module: payload.module,
            message: payload.message
        )
    }

    private static func defaultLogDirectory() -> URL? {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedKeys.sharedGroup
        )
        let subpath = Env.isTVOS ? "Library/Caches" : "AppExtensionLogs"
        return containerURL?.appendingPathComponent(subpath, isDirectory: true)
    }
}

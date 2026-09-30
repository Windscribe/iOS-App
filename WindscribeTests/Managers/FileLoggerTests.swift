//
//  FileLoggerTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-08-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe
import XCTest

final class FileLoggerTests: XCTestCase {
    // MARK: - Tests

    func testLogLevelUsesCompactRawValueAndStableExportValue() {
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.error.rawValue, 2)
        XCTAssertEqual(LogLevel.debug.stringValue, "debug")
        XCTAssertEqual(LogLevel.info.stringValue, "info")
        XCTAssertEqual(LogLevel.error.stringValue, "error")
    }

    func testLogProcessUsesDistinctTargetDirectories() {
        XCTAssertEqual(LogProcess.packetTunnel.rawValue, "packet-tunnel")
        XCTAssertEqual(LogProcess.wireGuardTunnel.rawValue, "wireguard-tunnel")
        XCTAssertEqual(LogProcess.appIntents.rawValue, "app-intents")
        XCTAssertEqual(LogProcess.siriIntents.rawValue, "siri-intents")
        XCTAssertEqual(LogProcess.homeWidget.rawValue, "home-widget")
        XCTAssertEqual(
            Set(LogProcess.allCases.map(\.rawValue)).count,
            LogProcess.allCases.count
        )
    }

    func testStorageBudgetUsesBoundedProcessAndSegmentDefaults() {
        XCTAssertEqual(LogStorageBudget.maximumBytesPerProcess, 10 * 1024 * 1024)
        XCTAssertEqual(LogStorageBudget.maximumSegmentBytes, 1024 * 1024)
    }

    func testBinaryCodecRoundTripsRecord() throws {
        let codec = BinaryLogRecordCodec()
        let record = LogRecord(
            timestamp: 1_700_000_000.125,
            level: .error,
            module: "FileLoggerTests",
            message: "round trip"
        )

        let encoded = try codec.encode(record)
        switch codec.decodeNext(from: encoded) {
        case let .record(decoded, consumedBytes):
            XCTAssertEqual(decoded, record)
            XCTAssertEqual(consumedBytes, encoded.count)
        default:
            XCTFail("Expected one decoded record")
        }
    }

    func testBinaryCodecUsesStableLittleEndianBytes() throws {
        let encoded = try BinaryLogRecordCodec().encode(
            LogRecord(
                timestamp: 1,
                level: .info,
                module: "M",
                message: "x"
            )
        )

        XCTAssertEqual(
            Array(encoded),
            [
                0x0D, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F,
                0x01,
                0x01, 0x00,
                0x4D,
                0x78
            ]
        )
    }

    func testBinaryCodecRejectsNonFiniteTimestamps() {
        let record = LogRecord(
            timestamp: .nan,
            level: .info,
            module: "FileLoggerTests",
            message: "invalid timestamp"
        )
        XCTAssertThrowsError(try BinaryLogRecordCodec().encode(record))
    }

    func testBinaryCodecConsumesInvalidUTF8FrameBeforeNextRecord() throws {
        let codec = BinaryLogRecordCodec()
        var invalid = try codec.encode(
            LogRecord(
                timestamp: 1,
                level: .info,
                module: "A",
                message: "x"
            )
        )
        invalid[invalid.index(before: invalid.endIndex)] = 0xFF
        let healthyRecord = LogRecord(
            timestamp: 2,
            level: .error,
            module: "B",
            message: "healthy"
        )
        let healthy = try codec.encode(healthyRecord)
        let combined = invalid + healthy

        guard case let .invalid(consumedBytes) = codec.decodeNext(from: combined) else {
            return XCTFail("Expected invalid first frame")
        }
        var remaining = combined
        remaining.removeFirst(consumedBytes)
        guard case let .record(decoded, _) = codec.decodeNext(from: remaining) else {
            return XCTFail("Expected healthy second frame")
        }
        XCTAssertEqual(decoded, healthyRecord)
    }

    func testMessagePolicyKeepsTwoLinesAndTruncatesUTF8Safely() {
        let policy = LogMessagePolicy()
        let lineLimited = policy.normalize(
            "first\nsecond\nthird",
            fitting: 100
        )
        XCTAssertEqual(lineLimited.components(separatedBy: .newlines).count, 2)
        XCTAssertTrue(lineLimited.hasSuffix(LogMessagePolicy.truncationMarker))

        let byteLimited = policy.normalize(
            String(repeating: "😀", count: 100),
            fitting: 64
        )
        XCTAssertLessThanOrEqual(byteLimited.utf8.count, 64)
        XCTAssertTrue(byteLimited.hasSuffix(LogMessagePolicy.truncationMarker))
    }

#if DEBUG
    func testDebugBurstWarningFiresOnceAfterThresholdInWindow() async throws {
        try await withTemporaryDirectory { directory in
            let recorder = BurstWarningRecorder()
            let writer = SegmentedLogWriter(
                now: { 1_700_000_000 },
                codec: BinaryLogRecordCodec(),
                segments: FileLogSegmentWriter(
                    baseURL: directory,
                    process: .app
                )
            )
            writer.setBurstWarningHandler(
                maximumRecords: 3,
                windowDuration: 1,
                warningCooldown: 60
            ) { recordCount in
                recorder.record(recordCount)
            }

            for _ in 0..<3 {
                writer.log(.info, module: "Burst", message: "record", flushImmediately: true)
            }
            XCTAssertEqual(recorder.recordCounts, [])

            writer.log(.info, module: "Burst", message: "record", flushImmediately: true)
            writer.log(.info, module: "Burst", message: "record", flushImmediately: true)
            XCTAssertEqual(recorder.recordCounts, [4])
            XCTAssertEqual(DebugLogBurst.maximumRecords, 1000)
        }
    }
#endif

    func testWriterCreationDoesNotCreateEmptySegment() async throws {
        try await withTemporaryDirectory { directory in
            _ = SegmentedLogWriter(
                now: { 1_700_000_000 },
                codec: BinaryLogRecordCodec(),
                segments: FileLogSegmentWriter(
                    baseURL: directory,
                    process: .homeWidget
                )
            )

            XCTAssertTrue(
                try segmentURLs(in: directory, process: .homeWidget).isEmpty
            )
        }
    }

    func testSegmentWriterPurgesExpiredFilesInFIFOOrder() async throws {
        try await withTemporaryDirectory { directory in
            let bucketDuration: TimeInterval = 60 * 60
            let currentTime: TimeInterval = 1_700_100_000
            let cutoff = currentTime - (2 * bucketDuration)
            let writer = FileLogSegmentWriter(
                baseURL: directory,
                process: .app,
                bucketDuration: bucketDuration
            )
            let oldest = try writer.createSegment(
                bucketStart: currentTime - (4 * bucketDuration),
                sequence: 0,
                header: Data("header".utf8)
            )
            let nextOldest = try writer.createSegment(
                bucketStart: currentTime - (3 * bucketDuration),
                sequence: 0,
                header: Data("header".utf8)
            )
            let retained = try writer.createSegment(
                bucketStart: cutoff,
                sequence: 0,
                header: Data("header".utf8)
            )

            try writer.removeClosedSegments(
                olderThan: cutoff,
                retainingAtMost: .max
            )

            XCTAssertFalse(FileManager.default.fileExists(atPath: oldest.url.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: nextOldest.url.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: retained.url.path))
        }
    }

    func testSegmentWriterPurgesOldestFilesToFitByteBudget() async throws {
        try await withTemporaryDirectory { directory in
            let writer = FileLogSegmentWriter(
                baseURL: directory,
                process: .app
            )
            var segments: [LogSegment] = []
            for index in 0..<3 {
                let segment = try writer.createSegment(
                    bucketStart: TimeInterval(index * 60 * 60),
                    sequence: 0,
                    header: Data(repeating: 0, count: 10)
                )
                try writer.append(Data(repeating: 1, count: 30), to: segment)
                segments.append(segment)
            }

            try writer.removeClosedSegments(
                olderThan: -1,
                retainingAtMost: 80
            )

            XCTAssertFalse(FileManager.default.fileExists(atPath: segments[0].url.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: segments[1].url.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: segments[2].url.path))
        }
    }

    func testLoggerWritesBinarySegmentInItsProcessDirectory() async throws {
        try await withTemporaryDirectory { directory in
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .packetTunnel,
                now: { 1_700_000_000 }
            )

            logger.logI("FileLoggerTests", "binary segment", flushImmediately: true)
            _ = try await logger.getLogData()

            let segments = try segmentURLs(
                in: directory,
                process: .packetTunnel
            )
            XCTAssertEqual(segments.count, 1)
            let data = try Data(contentsOf: XCTUnwrap(segments.first))
            XCTAssertTrue(data.starts(with: BinaryLogRecordCodec().segmentHeader))
            XCTAssertFalse(FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("windscribe.log").path
            ))
        }
    }

    func testLoggerRotatesBySizeAndKeepsProcessStorageWithinBudget() async throws {
        try await withTemporaryDirectory { directory in
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                maximumSegmentBytes: 18_000,
                maximumStoredBytes: 40_000,
                now: { 1_700_000_000 }
            )
            for index in 0..<6 {
                logger.logI(
                    "Record\(index)",
                    String(repeating: "x", count: 10_000),
                    flushImmediately: true
                )
            }

            let output = try await logger.getLogData()
            let segments = try segmentURLs(in: directory, process: .app)
            let storedBytes = try segments.reduce(into: 0) { result, url in
                result += try XCTUnwrap(
                    url.resourceValues(forKeys: [.fileSizeKey]).fileSize
                )
            }

            XCTAssertGreaterThan(segments.count, 1)
            XCTAssertLessThan(segments.count, 6)
            XCTAssertLessThanOrEqual(storedBytes, 40_000)
            XCTAssertFalse(output.contains("Record0"))
            XCTAssertTrue(output.contains("Record5"))
        }
    }

    func testExportProducesExpectedJSONShape() async throws {
        try await withTemporaryDirectory { directory in
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { 1_700_000_000.125 }
            )

            logger.logE("FileLoggerTests", "export shape", flushImmediately: true)
            let output = try await logger.getLogData()
            let records = try jsonRecords(from: output)
            let record = try XCTUnwrap(records.first {
                $0["msg"] == "export shape"
            })

            XCTAssertEqual(record["lvl"], "error")
            XCTAssertEqual(record["mod"], "FileLoggerTests")
            XCTAssertEqual(Set(record.keys), Set(["tm", "lvl", "mod", "msg"]))
            XCTAssertNotNil(makeLogDateFormatter().date(from: try XCTUnwrap(record["tm"])))
            XCTAssertEqual(records.filter { $0["mod"] == "LogMetadata" }.count, 1)
            XCTAssertEqual(records.last?["mod"], "LogMetadata")
        }
    }

    func testExportHasNoLegacyCharacterCap() async throws {
        try await withTemporaryDirectory { directory in
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { 1_700_000_000 }
            )
            for index in 0..<9 {
                logger.logI(
                    "LargeExport",
                    "\(index) " + String(repeating: "a", count: 15_000),
                    flushImmediately: true
                )
            }

            let output = try await logger.getLogData()
            let records = try jsonRecords(from: output).filter {
                $0["mod"] == "LargeExport"
            }
            XCTAssertEqual(records.count, 9)
            XCTAssertGreaterThan(output.count, 120_000)
        }
    }

    func testExportReturnsBeforeBackgroundCleanupCompletes() async throws {
        try await withTemporaryDirectory { directory in
            let segments = BlockingCleanupLogSegmentReader()
            let exporter = JSONLogExporter(
                now: { 1_700_000_000 },
                segments: segments,
                codec: BinaryLogRecordCodec(),
                metadata: TestLogMetadataProvider(),
                exportDirectory: directory
            )
            let start = Date()

            let artifact = try await exporter.exportRetainedLogs()
            defer {
                segments.releaseCleanup()
                try? FileManager.default.removeItem(at: artifact.url)
            }

            XCTAssertLessThan(Date().timeIntervalSince(start), 2)
            XCTAssertTrue(segments.waitForCleanup())
        }
    }

    func testExportIncludesAllProcessDirectoriesWithoutGlobalTimestampSort() async throws {
        try await withTemporaryDirectory { directory in
            let appLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { 1_700_000_100 }
            )
            let tunnelLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .packetTunnel,
                now: { 1_700_000_000 }
            )

            appLogger.logI("AppRecord", "app", flushImmediately: true)
            tunnelLogger.logI("TunnelRecord", "tunnel", flushImmediately: true)
            _ = try await tunnelLogger.getLogData()
            let output = try await appLogger.getLogData()

            XCTAssertEqual(try segmentURLs(in: directory, process: .app).count, 1)
            XCTAssertEqual(
                try segmentURLs(in: directory, process: .packetTunnel).count,
                1
            )
            XCTAssertLessThan(
                try XCTUnwrap(output.range(of: "AppRecord")?.lowerBound),
                try XCTUnwrap(output.range(of: "TunnelRecord")?.lowerBound)
            )
        }
    }

    func testDefaultRetentionIsTwentyFourHours() {
        XCTAssertEqual(LogRetention.duration, 24 * 60 * 60)
        XCTAssertEqual(LogRetention.submissionDuration, 2 * 60 * 60)
    }

    func testViewExportsTwentyFourHoursWhileSubmissionExportsTwoHours() async throws {
        try await withTemporaryDirectory { directory in
            let currentTime: TimeInterval = 1_700_100_000
            let olderLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { currentTime - (3 * 60 * 60) }
            )
            olderLogger.logI("OlderRecord", "three hours old", flushImmediately: true)

            let recentLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { currentTime - (60 * 60) }
            )
            recentLogger.logI("RecentRecord", "one hour old", flushImmediately: true)

            let currentLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { currentTime }
            )
            XCTAssertEqual(try segmentURLs(in: directory, process: .app).count, 2)

            let viewedLogs = try await currentLogger.getLogData()
            let submittedLogs = try await currentLogger.getLogData(for: .submission)

            XCTAssertTrue(viewedLogs.contains("OlderRecord"))
            XCTAssertTrue(viewedLogs.contains("RecentRecord"))
            XCTAssertFalse(submittedLogs.contains("OlderRecord"))
            XCTAssertTrue(submittedLogs.contains("RecentRecord"))
            XCTAssertEqual(try segmentURLs(in: directory, process: .app).count, 3)
        }
    }

    func testConfiguredRetentionPurgesExpiredSegmentsAndKeepsCutoffRecords() async throws {
        try await withTemporaryDirectory { directory in
            let currentTime: TimeInterval = 1_700_100_000
            let retentionDuration: TimeInterval = 2 * 60 * 60
            let cutoff = currentTime - retentionDuration
            let expiredLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                retentionDuration: retentionDuration,
                now: { cutoff - (60 * 60) }
            )
            expiredLogger.logI("ExpiredRecord", "expired", flushImmediately: true)

            let cutoffLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                retentionDuration: retentionDuration,
                now: { cutoff }
            )
            cutoffLogger.logI("CutoffRecord", "cutoff", flushImmediately: true)

            let currentLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                retentionDuration: retentionDuration,
                now: { currentTime }
            )
            currentLogger.logI("CurrentRecord", "current", flushImmediately: true)
            let output = try await currentLogger.getLogData()

            XCTAssertFalse(output.contains("ExpiredRecord"))
            XCTAssertTrue(output.contains("CutoffRecord"))
            XCTAssertTrue(output.contains("CurrentRecord"))
            XCTAssertEqual(try segmentURLs(in: directory, process: .app).count, 2)
        }
    }

    func testExportIgnoresIncompleteFinalRecord() async throws {
        try await withTemporaryDirectory { directory in
            let timestamp: TimeInterval = 1_700_000_000
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .wireGuardTunnel,
                now: { timestamp }
            )
            logger.logI("CompleteRecord", "complete", flushImmediately: true)
            _ = try await logger.getLogData()

            let segment = try XCTUnwrap(
                segmentURLs(in: directory, process: .wireGuardTunnel).first
            )
            let incompleteRecord = try BinaryLogRecordCodec().encode(
                LogRecord(
                    timestamp: timestamp,
                    level: .info,
                    module: "IncompleteRecord",
                    message: "incomplete"
                )
            )
            let handle = try FileHandle(forWritingTo: segment)
            handle.seekToEndOfFile()
            handle.write(incompleteRecord.prefix(2))
            handle.closeFile()

            let restartedLogger = FileLoggerImpl(
                logDirectory: directory,
                process: .wireGuardTunnel,
                now: { timestamp + 1 }
            )
            restartedLogger.logI(
                "RestartedRecord",
                "new segment",
                flushImmediately: true
            )
            let output = try await restartedLogger.getLogData()
            XCTAssertTrue(output.contains("CompleteRecord"))
            XCTAssertTrue(output.contains("RestartedRecord"))
            XCTAssertFalse(output.contains("IncompleteRecord"))
            XCTAssertEqual(
                try segmentURLs(in: directory, process: .wireGuardTunnel).count,
                2
            )
        }
    }

    func testUnreadableSegmentDoesNotBlockHealthySegments() async throws {
        try await withTemporaryDirectory { directory in
            let timestamp: TimeInterval = 1_700_000_000
            let corruptDirectory = directory.appendingPathComponent(
                LogProcess.packetTunnel.rawValue,
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: corruptDirectory,
                withIntermediateDirectories: true
            )
            try Data("not-a-segment".utf8).write(
                to: corruptDirectory.appendingPathComponent(
                    "segment-1699999200-0-corrupt.wslg"
                )
            )

            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { timestamp }
            )
            logger.logI("HealthyRecord", "healthy", flushImmediately: true)
            let output = try await logger.getLogData()

            XCTAssertTrue(output.contains("HealthyRecord"))
        }
    }

    func testWSNetPayloadPreservesLevelModuleMessageAndTimestamp() async throws {
        try await withTemporaryDirectory { directory in
            let timestamp: TimeInterval = 1_700_000_000
            let timestampString = makeLogDateFormatter().string(
                from: Date(timeIntervalSince1970: timestamp - 30)
            )
            let payload = "{\"tm\":\"\(timestampString)\"," +
                "\"lvl\":\"error\",\"mod\":\"WSNet\",\"msg\":\"payload\"}"
            let debugPayload = "{\"tm\":\"\(timestampString)\"," +
                "\"lvl\":\"debug\",\"mod\":\"WSNetDebug\"," +
                "\"msg\":\"debug payload\"}"
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { timestamp }
            )

            logger.logWSNet(payload)
            logger.logWSNet(debugPayload)
            logger.logWSNet("not json")
            let output = try await logger.getLogData()
            let records = try jsonRecords(from: output)

            let parsed = try XCTUnwrap(records.first { $0["mod"] == "WSNet" })
            XCTAssertEqual(parsed["tm"], timestampString)
            XCTAssertEqual(parsed["lvl"], "error")
            XCTAssertEqual(parsed["msg"], "payload")
            XCTAssertTrue(records.contains {
                $0["mod"] == "wsnet" && $0["msg"] == "not json"
            })
#if DEBUG
            XCTAssertTrue(records.contains {
                $0["mod"] == "WSNetDebug" && $0["lvl"] == "debug"
            })
#else
            XCTAssertFalse(records.contains { $0["mod"] == "WSNetDebug" })
#endif
        }
    }

    func testInitializationArchivesAndExportsLegacyLogFile() async throws {
        try await withTemporaryDirectory { directory in
            let timestamp: TimeInterval = 1_700_000_000
            let timestampString = makeLogDateFormatter().string(
                from: Date(timeIntervalSince1970: timestamp - 60)
            )
            let legacyLine = "{\"tm\": \"\(timestampString)\", " +
                "\"lvl\": \"info\", \"mod\": \"LegacyRecord\", " +
                "\"msg\": \"legacy\"}"
            let legacyLogURL = directory.appendingPathComponent(
                LegacyLogArchive.sourceFileName
            )
            try (legacyLine + "\n").write(
                to: legacyLogURL,
                atomically: true,
                encoding: .utf8
            )

            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { timestamp }
            )

            XCTAssertFalse(FileManager.default.fileExists(atPath: legacyLogURL.path))
            let archivedFiles = try LegacyLogArchive.files(in: directory)
            let archivedFile = try XCTUnwrap(archivedFiles.first)
            XCTAssertEqual(archivedFiles.count, 1)
            XCTAssertEqual(
                try String(contentsOf: archivedFile, encoding: .utf8),
                legacyLine + "\n"
            )

            let output = try await logger.getLogData()
            XCTAssertTrue(output.contains("LegacyRecord"))
            XCTAssertTrue(output.contains(timestampString))
        }
    }

    func testExportRemovesExpiredLegacyArchive() async throws {
        try await withTemporaryDirectory { directory in
            let timestamp: TimeInterval = 1_700_000_000
            let legacyLogURL = directory.appendingPathComponent(
                LegacyLogArchive.sourceFileName
            )
            try "legacy".write(
                to: legacyLogURL,
                atomically: true,
                encoding: .utf8
            )
            let archivedFile = try XCTUnwrap(
                LegacyLogArchive.archive(
                    in: directory,
                    at: timestamp - LogRetention.duration - (60 * 60)
                )
            )

            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { timestamp }
            )
            _ = try await logger.getLogData()

            let wasRemoved = await waitForRemoval(of: archivedFile)
            XCTAssertTrue(wasRemoved)
        }
    }

    func testConcurrentCallsProduceAllRecords() async throws {
        try await withTemporaryDirectory { directory in
            let logger = FileLoggerImpl(
                logDirectory: directory,
                process: .app,
                now: { 1_700_000_000 }
            )

            DispatchQueue.concurrentPerform(iterations: 100) { index in
                logger.logI("ConcurrentRecord", "record \(index)")
            }

            let output = try await logger.getLogData()
            let records = try jsonRecords(from: output).filter {
                $0["mod"] == "ConcurrentRecord"
            }
            XCTAssertEqual(records.count, 100)
        }
    }

    func testPendingQueueDropsExcessRecordsWhileSinkIsBlocked() async {
        let segments = BlockingLogSegmentWriter()
        let writer = SegmentedLogWriter(
            now: { 1_700_000_000 },
            codec: BinaryLogRecordCodec(),
            segments: segments,
            batchFlushInterval: 60 * 60,
            batchMaximumCount: 1,
            pendingMaximumCount: 5
        )

        writer.log(.info, module: "Blocked", message: "first")
        XCTAssertTrue(segments.waitForFirstAppend())

        for index in 0..<100 {
            writer.log(.info, module: "Blocked", message: "pending \(index)")
        }

        segments.releaseFirstAppend()
        await writer.flush()

        XCTAssertEqual(segments.appendCallCount, 5)
    }

    // MARK: - Private Methods

    private func waitForRemoval(
        of url: URL,
        timeout: TimeInterval = 2
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while FileManager.default.fileExists(atPath: url.path),
              Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return !FileManager.default.fileExists(atPath: url.path)
    }

    private func withTemporaryDirectory(
        _ body: (URL) async throws -> Void
    ) async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        try await body(directory)
    }

    private func segmentURLs(
        in directory: URL,
        process: LogProcess
    ) throws -> [URL] {
        let processDirectory = directory.appendingPathComponent(
            process.rawValue,
            isDirectory: true
        )
        guard FileManager.default.fileExists(atPath: processDirectory.path) else {
            return []
        }
        return try FileManager.default.contentsOfDirectory(
            at: processDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "wslg" }
    }

    private func jsonRecords(from output: String) throws -> [[String: String]] {
        try output
            .split(separator: "\n")
            .map { line in
                let data = Data(line.utf8)
                return try XCTUnwrap(
                    JSONSerialization.jsonObject(with: data) as? [String: String]
                )
            }
    }

    private func makeLogDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }
}

#if DEBUG
private final class BurstWarningRecorder: @unchecked Sendable {
    // MARK: - Properties

    var recordCounts: [Int] {
        lock.lock()
        defer { lock.unlock() }
        return counts
    }

    private let lock = NSLock()
    private var counts: [Int] = []

    // MARK: - Internal Methods

    func record(_ count: Int) {
        lock.lock()
        counts.append(count)
        lock.unlock()
    }
}
#endif

private final class BlockingLogSegmentWriter: LogSegmentWriting, @unchecked Sendable {
    // MARK: - Properties

    var appendCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return appendCalls
    }

    private let lock = NSLock()
    private let firstAppendStarted = DispatchSemaphore(value: 0)
    private let firstAppendRelease = DispatchSemaphore(value: 0)
    private var appendCalls = 0

    // MARK: - Internal Methods

    func createSegment(
        bucketStart: TimeInterval,
        sequence: UInt32,
        header _: Data
    ) throws -> LogSegment {
        LogSegment(
            process: .app,
            bucketStart: bucketStart,
            sequence: sequence,
            url: FileManager.default.temporaryDirectory
                .appendingPathComponent("blocked-segment")
        )
    }

    func append(_: Data, to _: LogSegment) throws {
        lock.lock()
        appendCalls += 1
        let isFirstAppend = appendCalls == 1
        lock.unlock()

        if isFirstAppend {
            firstAppendStarted.signal()
            _ = firstAppendRelease.wait(timeout: .now() + 5)
        }
    }

    func removeClosedSegments(
        olderThan _: TimeInterval,
        retainingAtMost _: Int
    ) throws {}

    func waitForFirstAppend() -> Bool {
        firstAppendStarted.wait(timeout: .now() + 5) == .success
    }

    func releaseFirstAppend() {
        firstAppendRelease.signal()
    }
}

private struct TestLogMetadataProvider: LogMetadataProviding, Sendable {
    func metadataRecord(at timestamp: TimeInterval) -> LogRecord {
        LogRecord(
            timestamp: timestamp,
            level: .info,
            module: "TestMetadata",
            message: "test"
        )
    }
}

private final class BlockingCleanupLogSegmentReader: LogSegmentReading, @unchecked Sendable {
    // MARK: - Properties

    private let cleanupStarted = DispatchSemaphore(value: 0)
    private let cleanupRelease = DispatchSemaphore(value: 0)

    // MARK: - Internal Methods

    func segments(
        for _: [LogProcess],
        newerThan _: TimeInterval
    ) throws -> [LogSegment] {
        []
    }

    func open(_: LogSegment) throws -> FileHandle {
        throw NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileNoSuchFileError
        )
    }

    func removeClosedSegments(olderThan _: TimeInterval) throws {
        cleanupStarted.signal()
        _ = cleanupRelease.wait(timeout: .now() + 5)
    }

    func waitForCleanup() -> Bool {
        cleanupStarted.wait(timeout: .now() + 2) == .success
    }

    func releaseCleanup() {
        cleanupRelease.signal()
    }
}

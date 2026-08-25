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
    func testFlushAppendsWithoutRewritingExistingLogFile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logger = FileLoggerImpl(testLogDirectory: directory)
        let logFileURL = directory.appendingPathComponent("windscribe.log")
        try "malformed existing line\n".write(to: logFileURL, atomically: true, encoding: .utf8)

        logger.logI("FileLoggerTests", "append-only flush")
        _ = try await logger.getLogData()

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertTrue(content.hasPrefix("malformed existing line\n"))
        XCTAssertTrue(content.contains("append-only flush"))
    }

    func testFlushCompactsLogFileAfterItExceedsSizeLimit() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logger = FileLoggerImpl(testLogDirectory: directory)
        let logFileURL = directory.appendingPathComponent("windscribe.log")

        var oversizedData = Data(repeating: 0x78, count: 2 * 1024 * 1024)
        oversizedData.append(0x0A)
        try oversizedData.write(to: logFileURL)

        logger.logI("FileLoggerTests", "size-triggered compaction")
        _ = try await logger.getLogData()

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("size-triggered compaction"))
        XCTAssertLessThanOrEqual(content.utf8.count, 512 * 1024)
    }

    func testCompactionDropsLogsOlderThan24Hours() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logger = FileLoggerImpl(testLogDirectory: directory)
        let logFileURL = directory.appendingPathComponent("windscribe.log")
        let formatter = makeLogDateFormatter()
        let oldTimestamp = formatter.string(from: Date().addingTimeInterval(-25 * 60 * 60))
        let recentTimestamp = formatter.string(from: Date().addingTimeInterval(-60))
        let oldLine = "{\"tm\": \"\(oldTimestamp)\", \"lvl\": \"info\", \"mod\": \"FileLoggerTests\", \"msg\": \"expired log\"}"
        let recentLine = "{\"tm\": \"\(recentTimestamp)\", \"lvl\": \"info\", \"mod\": \"FileLoggerTests\", \"msg\": \"recent log\"}"
        var oversizedData = Data(repeating: 0x78, count: 512 * 1024)
        oversizedData.append(Data("\n\(oldLine)\n\(recentLine)\n".utf8))
        try oversizedData.write(to: logFileURL)

        logger.logI("FileLoggerTests", "retention-triggered compaction")
        _ = try await logger.getLogData()

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertFalse(content.contains("expired log"))
        XCTAssertTrue(content.contains("recent log"))
        XCTAssertTrue(content.contains("retention-triggered compaction"))
    }

    func testExportPreservesExistingTimestampString() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logger = FileLoggerImpl(testLogDirectory: directory)
        let logFileURL = directory.appendingPathComponent("windscribe.log")
        let formatter = makeLogDateFormatter()
        let timestampString = formatter.string(from: Date().addingTimeInterval(-60))
        let existingLine = "{\"tm\": \"\(timestampString)\", \"lvl\": \"info\", \"mod\": \"FileLoggerTests\", \"msg\": \"existing timestamp\"}"
        try "\(existingLine)\n".write(to: logFileURL, atomically: true, encoding: .utf8)

        let exportedLogs = try await logger.getLogData()

        XCTAssertTrue(exportedLogs.contains(existingLine))
    }

    func testConcurrentLogCallsProduceParseableTimestamps() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logger = FileLoggerImpl(testLogDirectory: directory)

        DispatchQueue.concurrentPerform(iterations: 100) { index in
            logger.logI("FileLoggerTests", "concurrent timestamp \(index)")
        }

        let exportedLogs = try await logger.getLogData()
        let formatter = makeLogDateFormatter()
        let concurrentLines = exportedLogs
            .components(separatedBy: .newlines)
            .filter { $0.contains("concurrent timestamp") }

        XCTAssertEqual(concurrentLines.count, 100)
        for line in concurrentLines {
            let data = try XCTUnwrap(line.data(using: .utf8))
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
            let timestampString = try XCTUnwrap(object["tm"])
            XCTAssertNotNil(formatter.date(from: timestampString))
        }
    }

    private func makeLogDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }
}

private extension FileLoggerImpl {
    convenience init(testLogDirectory: URL) {
        self.init()
        logDirectory = testLogDirectory
    }
}

//
//  LogProtocols.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

// MARK: - LogWriting

protocol LogWriting: Sendable {
    func log(_ level: LogLevel, module: String, message: String)
}

extension LogWriting {
    func logD(_ module: String, _ message: String) {
        log(.debug, module: module, message: message)
    }

    func logI(_ module: String, _ message: String) {
        log(.info, module: module, message: message)
    }

    func logE(_ module: String, _ message: String) {
        log(.error, module: module, message: message)
    }
}

// MARK: - LogExporting

protocol LogExporting: Sendable {
    func exportLogs(for purpose: LogExportPurpose) async throws -> LogExportArtifact
}

extension LogExporting {
    func exportRetainedLogs() async throws -> LogExportArtifact {
        try await exportLogs(for: .viewing)
    }
}

// MARK: - LogRecordCoding

enum LogRecordDecodeResult: Sendable {
    case record(LogRecord, consumedBytes: Int)
    case incomplete
    case invalid(consumedBytes: Int)
    case invalidHeader
}

protocol LogRecordCoding: Sendable {
    var segmentHeader: Data { get }
    var maximumRecordPayloadBytes: Int { get }

    func maximumMessageBytes(module: String) -> Int
    func encode(_ record: LogRecord) throws -> Data
    func decodeNext(from data: Data) -> LogRecordDecodeResult
}

// MARK: - LogSegmentWriting

protocol LogSegmentWriting: Sendable {
    func createSegment(
        bucketStart: TimeInterval,
        sequence: UInt32,
        header: Data
    ) throws -> LogSegment

    func append(_ data: Data, to segment: LogSegment) throws
    func removeClosedSegments(
        olderThan cutoff: TimeInterval,
        retainingAtMost maximumBytes: Int
    ) throws
}

// MARK: - LogSegmentReading

protocol LogSegmentReading: Sendable {
    func segments(
        for processes: [LogProcess],
        newerThan cutoff: TimeInterval
    ) throws -> [LogSegment]

    func open(_ segment: LogSegment) throws -> FileHandle
    func removeClosedSegments(olderThan cutoff: TimeInterval) throws
}

// MARK: - LogMetadataProviding

protocol LogMetadataProviding: Sendable {
    func metadataRecord(at timestamp: TimeInterval) -> LogRecord
}

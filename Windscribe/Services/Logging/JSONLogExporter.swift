//
//  JSONLogExporter.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

final class JSONLogFormatter: @unchecked Sendable {
    // MARK: - Properties

    private let lock = NSLock()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    // MARK: - Internal Methods

    func format(_ record: LogRecord) -> String {
        lock.lock()
        let timestamp = dateFormatter.string(
            from: Date(timeIntervalSince1970: record.timestamp)
        )
        lock.unlock()
        return "{\"tm\": \(quoted(timestamp)), " +
            "\"lvl\": \(quoted(record.level.stringValue)), " +
            "\"mod\": \(quoted(record.module)), " +
            "\"msg\": \(quoted(record.message))}"
    }

    func timestamp(from value: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        return dateFormatter.date(from: value)?.timeIntervalSince1970
    }

    // MARK: - Private Methods

    private func quoted(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let encoded = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return encoded
    }
}

struct JSONLogExporter: LogExporting, Sendable {
    // MARK: - Properties

    private let now: @Sendable () -> TimeInterval
    private let segments: any LogSegmentReading
    private let codec: any LogRecordCoding
    private let formatter: JSONLogFormatter
    private let metadata: any LogMetadataProviding
    private let exportDirectory: URL
    private let retentionDuration: TimeInterval
    private let readChunkBytes: Int
    private let openOutput: @Sendable (URL) throws -> FileHandle

    // MARK: - Initializer

    init(
        now: @escaping @Sendable () -> TimeInterval,
        segments: any LogSegmentReading,
        codec: any LogRecordCoding,
        formatter: JSONLogFormatter = JSONLogFormatter(),
        metadata: any LogMetadataProviding,
        exportDirectory: URL,
        retentionDuration: TimeInterval = LogRetention.duration,
        readChunkBytes: Int = 64 * 1024,
        openOutput: @escaping @Sendable (URL) throws -> FileHandle = { try FileHandle(forWritingTo: $0) }
    ) {
        self.now = now
        self.segments = segments
        self.codec = codec
        self.formatter = formatter
        self.metadata = metadata
        self.exportDirectory = exportDirectory
        self.retentionDuration = retentionDuration
        self.readChunkBytes = readChunkBytes
        self.openOutput = openOutput
    }

    // MARK: - LogExporting

    func exportLogs(for purpose: LogExportPurpose) async throws -> LogExportArtifact {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let exportTime = self.now()
                let exportCutoff = exportTime - purpose.duration(
                    retentionDuration: self.retentionDuration
                )
                let retentionCutoff = exportTime - self.retentionDuration
                do {
                    continuation.resume(
                        returning: try self.export(
                            at: exportTime,
                            newerThan: exportCutoff
                        )
                    )
                } catch {
                    continuation.resume(throwing: error)
                }
                self.scheduleCleanup(olderThan: retentionCutoff)
            }
        }
    }

    // MARK: - Private Methods

    private func export(
        at exportTime: TimeInterval,
        newerThan cutoff: TimeInterval
    ) throws -> LogExportArtifact {
        try FileManager.default.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true
        )

        let outputURL = exportDirectory.appendingPathComponent(
            "windscribe-log-export-\(UUID().uuidString).json"
        )
        _ = FileManager.default.createFile(atPath: outputURL.path, contents: nil)

        do {
            let output = try openOutput(outputURL)
            defer { try? output.close() }

            var outputBuffer = Data()

            func flushOutputBuffer() throws {
                guard !outputBuffer.isEmpty else { return }
                try output.write(contentsOf: outputBuffer)
                outputBuffer.removeAll(keepingCapacity: true)
            }

            func append(_ record: LogRecord) throws {
                guard record.timestamp >= cutoff else { return }
                outputBuffer.append(
                    Data((formatter.format(record) + "\n").utf8)
                )
                if outputBuffer.count >= readChunkBytes {
                    try flushOutputBuffer()
                }
            }

            for legacyLogURL in try archivedLegacyLogFiles(newerThan: cutoff) {
                try readLegacyRecords(
                    from: legacyLogURL,
                    consume: append
                )
            }

            for segment in try segments.segments(
                for: LogProcess.allCases,
                newerThan: cutoff
            ) {
                try readRecords(from: segment, consume: append)
            }

            try append(metadata.metadataRecord(at: exportTime))
            try flushOutputBuffer()
            try output.close()

            return LogExportArtifact(
                url: outputURL,
                contentType: "application/x-ndjson"
            )
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }

    private func readRecords(
        from segment: LogSegment,
        consume: (LogRecord) throws -> Void
    ) throws {
        guard let input = try? segments.open(segment) else { return }
        defer { try? input.close() }

        guard let snapshotLength = try? input.seekToEnd(),
              snapshotLength >= UInt64(codec.segmentHeader.count),
              snapshotLength <= UInt64(Int.max) else {
            return
        }
        guard (try? input.seek(toOffset: 0)) != nil else { return }

        guard let header = try? input.read(upToCount: codec.segmentHeader.count),
              header == codec.segmentHeader else { return }

        var buffer = Data()
        var remainingBytes = Int(snapshotLength) - header.count

        while remainingBytes > 0 {
            guard let chunk = try? input.read(upToCount: min(readChunkBytes, remainingBytes)),
                  !chunk.isEmpty else { break }
            remainingBytes -= chunk.count
            buffer.append(chunk)

            decodeLoop: while !buffer.isEmpty {
                switch codec.decodeNext(from: buffer) {
                case let .record(record, consumedBytes):
                    try consume(record)
                    buffer.removeFirst(consumedBytes)
                case let .invalid(consumedBytes):
                    buffer.removeFirst(consumedBytes)
                case .incomplete:
                    break decodeLoop
                case .invalidHeader:
                    return
                }
            }
        }
        // An incomplete final record is intentionally ignored. A later export can
        // read it after an active writer completes the append.
    }

    private func archivedLegacyLogFiles(
        newerThan cutoff: TimeInterval
    ) throws -> [URL] {
        try LegacyLogArchive.files(in: exportDirectory).filter { url in
            guard let archiveTimestamp = LegacyLogArchive.timestamp(from: url) else {
                return true
            }
            return archiveTimestamp > cutoff
        }
    }

    private func scheduleCleanup(olderThan cutoff: TimeInterval) {
        DispatchQueue.global(qos: .utility).async {
            try? self.segments.removeClosedSegments(olderThan: cutoff)
            guard let legacyFiles = try? LegacyLogArchive.files(
                in: self.exportDirectory
            ) else {
                return
            }
            for url in legacyFiles {
                guard let timestamp = LegacyLogArchive.timestamp(from: url),
                      timestamp <= cutoff else {
                    continue
                }
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func readLegacyRecords(
        from url: URL,
        consume: (LogRecord) throws -> Void
    ) throws {
        guard let input = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? input.close() }

        guard let snapshotLength = try? input.seekToEnd(),
              snapshotLength <= UInt64(Int.max) else { return }
        guard (try? input.seek(toOffset: 0)) != nil else { return }

        let maximumLegacyLineBytes = 1024 * 1024
        var line = Data()
        var droppingLine = false
        var remainingBytes = Int(snapshotLength)

        func processLine() throws {
            defer {
                line.removeAll(keepingCapacity: true)
                droppingLine = false
            }
            guard !droppingLine,
                  !line.isEmpty,
                  let object = try? JSONSerialization.jsonObject(with: line),
                  let values = object as? [String: String],
                  let timestampString = values["tm"],
                  let timestamp = formatter.timestamp(from: timestampString),
                  let module = values["mod"],
                  let message = values["msg"] else {
                return
            }

            try consume(
                LogRecord(
                    timestamp: timestamp,
                    level: LogLevel(stringValue: values["lvl"] ?? "") ?? .info,
                    module: module,
                    message: message
                )
            )
        }

        while remainingBytes > 0 {
            guard let chunk = try? input.read(upToCount: min(readChunkBytes, remainingBytes)),
                  !chunk.isEmpty else { break }
            remainingBytes -= chunk.count

            for byte in chunk {
                if byte == 0x0A {
                    try processLine()
                } else if !droppingLine {
                    if line.count < maximumLegacyLineBytes {
                        line.append(byte)
                    } else {
                        droppingLine = true
                    }
                }
            }
        }
        try processLine()
    }
}

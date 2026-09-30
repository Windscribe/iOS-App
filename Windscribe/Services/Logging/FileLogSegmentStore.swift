//
//  FileLogSegmentStore.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

enum LegacyLogArchive {
    // MARK: - Properties

    static let sourceFileName = "windscribe.log"

    private static let archivePrefix = "legacy-windscribe"
    private static let fileExtension = "log"

    // MARK: - Internal Methods

    static func archive(
        in directory: URL,
        at timestamp: TimeInterval
    ) throws -> URL? {
        guard timestamp.isFinite else { return nil }

        let sourceURL = directory.appendingPathComponent(sourceFileName)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return nil }

        let archiveTimestamp = String(format: "%.0f", floor(timestamp))
        let archiveURL = directory.appendingPathComponent(
            "\(archivePrefix)-\(archiveTimestamp)-\(UUID().uuidString).\(fileExtension)"
        )
        try FileManager.default.moveItem(at: sourceURL, to: archiveURL)
        return archiveURL
    }

    static func files(in directory: URL) throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }

        return try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter {
            $0.pathExtension == fileExtension &&
                $0.deletingPathExtension().lastPathComponent.hasPrefix("\(archivePrefix)-")
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    static func timestamp(from url: URL) -> TimeInterval? {
        let components = url.deletingPathExtension().lastPathComponent.split(separator: "-")
        guard components.count >= 4,
              components[0] == "legacy",
              components[1] == "windscribe" else {
            return nil
        }
        return TimeInterval(components[2])
    }
}

private enum LogSegmentFileName {
    static let fileExtension = "wslg"

    static func make(bucketStart: TimeInterval, sequence: UInt32) -> String {
        let bucket = String(format: "%.0f", bucketStart)
        return "segment-\(bucket)-\(sequence)-\(UUID().uuidString).\(fileExtension)"
    }

    static func parse(url: URL, process: LogProcess) -> LogSegment? {
        guard url.pathExtension == fileExtension else { return nil }

        let components = url.deletingPathExtension().lastPathComponent.split(separator: "-")
        guard components.count >= 4,
              components[0] == "segment",
              let bucketStart = TimeInterval(components[1]),
              let sequence = UInt32(components[2]) else {
            return nil
        }

        return LogSegment(
            process: process,
            bucketStart: bucketStart,
            sequence: sequence,
            url: url
        )
    }
}

final class FileLogSegmentWriter: LogSegmentWriting, @unchecked Sendable {
    // MARK: - Properties

    private let baseURL: URL
    private let process: LogProcess
    private let bucketDuration: TimeInterval

    private var knownSegments: [LogSegment]?

    private var processDirectory: URL {
        baseURL.appendingPathComponent(process.rawValue, isDirectory: true)
    }

    // MARK: - Initializer

    init(
        baseURL: URL,
        process: LogProcess,
        // Each segment time bucket covers one hour by default.
        bucketDuration: TimeInterval = 60 * 60
    ) {
        self.baseURL = baseURL
        self.process = process
        self.bucketDuration = bucketDuration
    }

    // MARK: - LogSegmentWriting

    func createSegment(
        bucketStart: TimeInterval,
        sequence: UInt32,
        header: Data
    ) throws -> LogSegment {
        let directory = processDirectory
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try loadKnownSegmentsIfNeeded()

        let url = directory.appendingPathComponent(
            LogSegmentFileName.make(bucketStart: bucketStart, sequence: sequence)
        )
        try header.write(to: url, options: .atomic)

        let segment = LogSegment(
            process: process,
            bucketStart: bucketStart,
            sequence: sequence,
            url: url
        )
        knownSegments?.append(segment)
        return segment
    }

    func append(_ data: Data, to segment: LogSegment) throws {
        guard !data.isEmpty else { return }

        let handle = try FileHandle(forWritingTo: segment.url)
        defer { handle.closeFile() }
        handle.seekToEndOfFile()
        handle.write(data)
    }

    func removeClosedSegments(
        olderThan cutoff: TimeInterval,
        retainingAtMost maximumBytes: Int
    ) throws {
        try loadKnownSegmentsIfNeeded()
        removeExpiredSegments(olderThan: cutoff)
        removeSegments(exceeding: maximumBytes)
    }

    // MARK: - Private Methods

    private func removeExpiredSegments(olderThan cutoff: TimeInterval) {
        while let oldest = knownSegments?.first,
              oldest.bucketStart + bucketDuration <= cutoff {
            guard removeOldestSegment() else {
                break
            }
        }
    }

    private func removeSegments(exceeding maximumBytes: Int) {
        let limit = max(0, maximumBytes)
        var storedBytes = knownSegments?.reduce(into: 0) { result, segment in
            result += segmentSize(segment)
        } ?? 0

        while storedBytes > limit, let oldest = knownSegments?.first {
            let oldestBytes = segmentSize(oldest)
            guard removeOldestSegment() else { break }
            storedBytes = max(0, storedBytes - oldestBytes)
        }
    }

    private func removeOldestSegment() -> Bool {
        guard let oldest = knownSegments?.first else { return false }

        do {
            try FileManager.default.removeItem(at: oldest.url)
            knownSegments?.removeFirst()
            return true
        } catch {
            guard !FileManager.default.fileExists(atPath: oldest.url.path) else {
                return false
            }
            knownSegments?.removeFirst()
            return true
        }
    }

    private func segmentSize(_ segment: LogSegment) -> Int {
        let attributes = try? FileManager.default.attributesOfItem(
            atPath: segment.url.path
        )
        return attributes?[.size] as? Int ?? 0
    }

    private func loadKnownSegmentsIfNeeded() throws {
        guard knownSegments == nil else { return }

        let directory = processDirectory
        guard FileManager.default.fileExists(atPath: directory.path) else {
            knownSegments = []
            return
        }

        knownSegments = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).compactMap {
            LogSegmentFileName.parse(url: $0, process: process)
        }.sorted {
            if $0.bucketStart != $1.bucketStart {
                return $0.bucketStart < $1.bucketStart
            }
            if $0.sequence != $1.sequence {
                return $0.sequence < $1.sequence
            }
            return $0.url.lastPathComponent < $1.url.lastPathComponent
        }
    }
}

struct FileLogSegmentReader: LogSegmentReading, Sendable {
    // MARK: - Properties

    private let baseURL: URL
    private let bucketDuration: TimeInterval

    // MARK: - Initializer

    init(
        baseURL: URL,
        // Each segment time bucket covers one hour by default.
        bucketDuration: TimeInterval = 60 * 60
    ) {
        self.baseURL = baseURL
        self.bucketDuration = bucketDuration
    }

    // MARK: - LogSegmentReading

    func segments(
        for processes: [LogProcess],
        newerThan cutoff: TimeInterval
    ) throws -> [LogSegment] {
        var result: [LogSegment] = []

        for process in processes {
            let directory = processDirectory(for: process)
            guard FileManager.default.fileExists(atPath: directory.path) else { continue }

            for url in try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) {
                guard let segment = LogSegmentFileName.parse(url: url, process: process),
                      segment.bucketStart + bucketDuration > cutoff else {
                    continue
                }
                result.append(segment)
            }
        }

        let processOrder = Dictionary(
            uniqueKeysWithValues: LogProcess.allCases.enumerated().map { ($1, $0) }
        )
        return result.sorted { lhs, rhs in
            let lhsProcess = processOrder[lhs.process] ?? Int.max
            let rhsProcess = processOrder[rhs.process] ?? Int.max
            if lhsProcess != rhsProcess {
                return lhsProcess < rhsProcess
            }
            if lhs.bucketStart != rhs.bucketStart {
                return lhs.bucketStart < rhs.bucketStart
            }
            if lhs.sequence != rhs.sequence {
                return lhs.sequence < rhs.sequence
            }
            return lhs.url.lastPathComponent < rhs.url.lastPathComponent
        }
    }

    func open(_ segment: LogSegment) throws -> FileHandle {
        try FileHandle(forReadingFrom: segment.url)
    }

    func removeClosedSegments(olderThan cutoff: TimeInterval) throws {
        for process in LogProcess.allCases {
            let directory = processDirectory(for: process)
            guard FileManager.default.fileExists(atPath: directory.path) else { continue }

            for url in try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) {
                guard let segment = LogSegmentFileName.parse(url: url, process: process),
                      segment.bucketStart + bucketDuration <= cutoff else {
                    continue
                }
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: - Private Methods

    private func processDirectory(for process: LogProcess) -> URL {
        baseURL.appendingPathComponent(process.rawValue, isDirectory: true)
    }
}

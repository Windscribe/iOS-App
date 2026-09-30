//
//  SegmentedLogWriter.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

final class SegmentedLogWriter: LogWriting, @unchecked Sendable {
    // MARK: - Properties

    private let queue = DispatchQueue(
        label: "com.windscribe.logging.segmented-writer",
        qos: .utility
    )
    private let queueKey = DispatchSpecificKey<Bool>()
    private let pendingSlots: DispatchSemaphore
    private let now: @Sendable () -> TimeInterval
    private let codec: any LogRecordCoding
    private let segments: any LogSegmentWriting
    private let messagePolicy: LogMessagePolicy
    private let batchFlushInterval: TimeInterval
    private let batchMaximumCount: Int
    private let batchMaximumBytes: Int
    private let bucketDuration: TimeInterval
    private let retentionDuration: TimeInterval
    private let maximumSegmentBytes: Int
    private let maximumStoredBytes: Int

    private var timer: DispatchSourceTimer?
    private var buffer: [LogRecord] = []
    private var bufferedBytes = 0
    private var activeSegment: LogSegment?
    private var activeSegmentBytes = 0

#if DEBUG
    private var burstWarningHandler: (@Sendable (Int) -> Void)?
    private var burstMaximumRecords = DebugLogBurst.maximumRecords
    private var burstWindowDuration = DebugLogBurst.windowDuration
    private var burstWarningCooldown = DebugLogBurst.warningCooldown
    private var burstWindowStart: TimeInterval?
    private var burstRecordCount = 0
    private var lastBurstWarningTime: TimeInterval?
#endif

    // MARK: - Lifecycle

    init(
        now: @escaping @Sendable () -> TimeInterval,
        codec: any LogRecordCoding,
        segments: any LogSegmentWriting,
        messagePolicy: LogMessagePolicy = LogMessagePolicy(),
        batchFlushInterval: TimeInterval = 10,
        batchMaximumCount: Int = 50,
        batchMaximumBytes: Int = 10_000,
        pendingMaximumCount: Int = 200,
        // Segments rotate across one-hour time buckets by default.
        bucketDuration: TimeInterval = 60 * 60,
        retentionDuration: TimeInterval = LogRetention.duration,
        maximumSegmentBytes: Int = LogStorageBudget.maximumSegmentBytes,
        maximumStoredBytes: Int = LogStorageBudget.maximumBytesPerProcess
    ) {
        self.now = now
        self.codec = codec
        self.segments = segments
        self.messagePolicy = messagePolicy
        self.batchFlushInterval = batchFlushInterval
        self.batchMaximumCount = batchMaximumCount
        self.batchMaximumBytes = batchMaximumBytes
        pendingSlots = DispatchSemaphore(value: max(1, pendingMaximumCount))
        self.bucketDuration = bucketDuration
        self.retentionDuration = retentionDuration
        let minimumSegmentBytes = codec.segmentHeader.count + 4 + codec.maximumRecordPayloadBytes
        self.maximumSegmentBytes = max(minimumSegmentBytes, maximumSegmentBytes)
        self.maximumStoredBytes = max(self.maximumSegmentBytes, maximumStoredBytes)

        queue.setSpecific(key: queueKey, value: true)
        startTimer()
        queue.async { [weak self] in
            guard let self else { return }
            self.maintainSegments(
                at: self.now(),
                retainingAtMost: self.maximumStoredBytes
            )
        }
    }

    deinit {
        timer?.setEventHandler {}
        timer?.cancel()

        if DispatchQueue.getSpecific(key: queueKey) != nil {
            flushLocked()
        } else {
            queue.sync {
                flushLocked()
            }
        }
    }

    // MARK: - LogWriting

    func log(_ level: LogLevel, module: String, message: String) {
        log(level, module: module, message: message, flushImmediately: false)
    }

    func log(
        _ level: LogLevel,
        module: String,
        message: String,
        flushImmediately: Bool
    ) {
        enqueue(
            LogRecord(
                timestamp: now(),
                level: level,
                module: module,
                message: message
            ),
            flushImmediately: flushImmediately
        )
    }

    func log(_ record: LogRecord, flushImmediately: Bool = false) {
        enqueue(record, flushImmediately: flushImmediately)
    }

    func flush() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                self?.flushLocked()
                continuation.resume()
            }
        }
    }

#if DEBUG
    func setBurstWarningHandler(
        maximumRecords: Int = DebugLogBurst.maximumRecords,
        windowDuration: TimeInterval = DebugLogBurst.windowDuration,
        warningCooldown: TimeInterval = DebugLogBurst.warningCooldown,
        handler: @escaping @Sendable (Int) -> Void
    ) {
        queue.sync {
            burstMaximumRecords = max(1, maximumRecords)
            burstWindowDuration = max(0.001, windowDuration)
            burstWarningCooldown = max(burstWindowDuration, warningCooldown)
            burstWarningHandler = handler
        }
    }
#endif

    // MARK: - Private Methods

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + batchFlushInterval,
            repeating: batchFlushInterval
        )
        timer.setEventHandler { [weak self] in
            self?.flushLocked()
        }
        timer.resume()
        self.timer = timer
    }

    private func enqueue(_ record: LogRecord, flushImmediately: Bool) {
        guard pendingSlots.wait(timeout: .now()) == .success else { return }

        let maximumMessageBytes = codec.maximumMessageBytes(module: record.module)
        guard maximumMessageBytes > 0 else {
            pendingSlots.signal()
            return
        }

        let normalizedRecord = LogRecord(
            timestamp: record.timestamp,
            level: record.level,
            module: record.module,
            message: messagePolicy.normalize(
                record.message,
                fitting: maximumMessageBytes
            )
        )

        if flushImmediately {
            defer { pendingSlots.signal() }
            if DispatchQueue.getSpecific(key: queueKey) != nil {
                addLocked(normalizedRecord, flushImmediately: true)
            } else {
                queue.sync {
                    addLocked(normalizedRecord, flushImmediately: true)
                }
            }
            return
        }

        let slots = pendingSlots
        queue.async { [weak self] in
            defer { slots.signal() }
            self?.addLocked(
                normalizedRecord,
                flushImmediately: false
            )
        }
    }

    private func addLocked(_ normalizedRecord: LogRecord, flushImmediately: Bool) {
#if DEBUG
        detectBurstLocked(at: now())
#endif
        buffer.append(normalizedRecord)
        bufferedBytes += normalizedRecord.module.utf8.count
        bufferedBytes += normalizedRecord.message.utf8.count
        bufferedBytes += 16

        if flushImmediately ||
            buffer.count >= batchMaximumCount ||
            bufferedBytes >= batchMaximumBytes {
            flushLocked()
        }
    }

#if DEBUG
    private func detectBurstLocked(at timestamp: TimeInterval) {
        guard timestamp.isFinite, let burstWarningHandler else { return }

        if let burstWindowStart,
           timestamp >= burstWindowStart,
           timestamp - burstWindowStart < burstWindowDuration {
            burstRecordCount += 1
        } else {
            burstWindowStart = timestamp
            burstRecordCount = 1
        }

        guard burstRecordCount > burstMaximumRecords else { return }
        if let lastBurstWarningTime,
           timestamp - lastBurstWarningTime < burstWarningCooldown {
            return
        }

        lastBurstWarningTime = timestamp
        burstWarningHandler(burstRecordCount)
    }
#endif

    private func flushLocked() {
        guard !buffer.isEmpty else { return }

        let records = buffer
        buffer.removeAll(keepingCapacity: true)
        bufferedBytes = 0

        var pendingData = Data()
        var pendingSegment: LogSegment?

        func writePendingData() {
            guard let segment = pendingSegment, !pendingData.isEmpty else { return }
            try? segments.append(pendingData, to: segment)
            pendingData.removeAll(keepingCapacity: true)
        }

        for record in records {
            guard record.timestamp.isFinite,
                  let encoded = try? codec.encode(record) else {
                continue
            }

            let bucketStart = floor(record.timestamp / bucketDuration) * bucketDuration
            let canReuseActiveSegment = activeSegment?.bucketStart == bucketStart &&
                activeSegmentBytes + encoded.count <= maximumSegmentBytes
            if !canReuseActiveSegment {
                writePendingData()
            }

            guard let segment = segment(
                for: record.timestamp,
                requiredBytes: encoded.count
            ) else {
                continue
            }

            if pendingSegment?.url != segment.url {
                writePendingData()
                pendingSegment = segment
            }

            pendingData.append(encoded)
            activeSegmentBytes += encoded.count
        }

        writePendingData()
    }

    private func segment(
        for timestamp: TimeInterval,
        requiredBytes: Int
    ) -> LogSegment? {
        let bucketStart = floor(timestamp / bucketDuration) * bucketDuration
        if let activeSegment,
           activeSegment.bucketStart == bucketStart,
           activeSegmentBytes + requiredBytes <= maximumSegmentBytes {
            return activeSegment
        }

        maintainSegments(
            at: timestamp,
            retainingAtMost: maximumStoredBytes - maximumSegmentBytes
        )

        let offsetMicroseconds = max(0, (timestamp - bucketStart) * 1_000_000)
        let sequence = UInt32(
            min(Double(UInt32.max), floor(offsetMicroseconds))
        )

        guard let segment = try? segments.createSegment(
            bucketStart: bucketStart,
            sequence: sequence,
            header: codec.segmentHeader
        ) else {
            return nil
        }

        activeSegment = segment
        activeSegmentBytes = codec.segmentHeader.count
        return segment
    }

    private func maintainSegments(
        at timestamp: TimeInterval,
        retainingAtMost maximumBytes: Int
    ) {
        guard timestamp.isFinite else { return }
        try? segments.removeClosedSegments(
            olderThan: timestamp - retentionDuration,
            retainingAtMost: maximumBytes
        )
    }
}

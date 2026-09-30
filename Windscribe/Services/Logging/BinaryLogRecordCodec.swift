//
//  BinaryLogRecordCodec.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

enum BinaryLogRecordCodecError: Error {
    case invalidTimestamp
    case moduleTooLarge
    case recordTooLarge
}

struct BinaryLogRecordCodec: LogRecordCoding, Sendable {
    // MARK: - Properties

    let maximumRecordPayloadBytes: Int

    // Float64 timestamp + UInt8 level + UInt16 module byte length.
    private static let fixedPayloadBytes = 8 + 1 + 2

    var segmentHeader: Data {
        Data([0x57, 0x53, 0x4C, 0x47, 0x01]) // WSLG + version 1
    }

    // MARK: - Initializer

    init(maximumRecordPayloadBytes: Int = 16 * 1024) {
        self.maximumRecordPayloadBytes = maximumRecordPayloadBytes
    }

    // MARK: - LogRecordCoding

    func maximumMessageBytes(module: String) -> Int {
        max(0, maximumRecordPayloadBytes - Self.fixedPayloadBytes - module.utf8.count)
    }

    func encode(_ record: LogRecord) throws -> Data {
        guard record.timestamp.isFinite else {
            throw BinaryLogRecordCodecError.invalidTimestamp
        }

        let moduleData = Data(record.module.utf8)
        let messageData = Data(record.message.utf8)

        guard moduleData.count <= Int(UInt16.max) else {
            throw BinaryLogRecordCodecError.moduleTooLarge
        }

        let payloadLength = Self.fixedPayloadBytes + moduleData.count + messageData.count
        guard payloadLength <= maximumRecordPayloadBytes else {
            throw BinaryLogRecordCodecError.recordTooLarge
        }

        var data = Data()
        data.reserveCapacity(4 + payloadLength)
        append(UInt32(payloadLength), to: &data)
        append(record.timestamp.bitPattern, to: &data)
        data.append(record.level.rawValue)
        append(UInt16(moduleData.count), to: &data)
        data.append(moduleData)
        data.append(messageData)
        return data
    }

    func decodeNext(from data: Data) -> LogRecordDecodeResult {
        guard data.count >= 4 else { return .incomplete }

        let payloadLength = Int(readUInt32(from: data, offset: 0))
        guard payloadLength >= Self.fixedPayloadBytes,
              payloadLength <= maximumRecordPayloadBytes else {
            return .invalidHeader
        }

        let consumedBytes = 4 + payloadLength
        guard data.count >= consumedBytes else { return .incomplete }

        let timestamp = TimeInterval(bitPattern: readUInt64(from: data, offset: 4))
        let levelOffset = 12
        let levelRawValue = byte(from: data, offset: levelOffset)
        let moduleLength = Int(readUInt16(from: data, offset: levelOffset + 1))
        let moduleStartOffset = levelOffset + 3
        let messageStartOffset = moduleStartOffset + moduleLength

        guard timestamp.isFinite,
              messageStartOffset <= consumedBytes,
              let level = LogLevel(rawValue: levelRawValue) else {
            return .invalid(consumedBytes: consumedBytes)
        }

        let moduleStart = data.index(
            data.startIndex,
            offsetBy: moduleStartOffset
        )
        let messageStart = data.index(
            data.startIndex,
            offsetBy: messageStartOffset
        )
        let recordEnd = data.index(
            data.startIndex,
            offsetBy: consumedBytes
        )

        guard let module = String(
                data: data.subdata(in: moduleStart..<messageStart),
                encoding: .utf8
              ),
              let message = String(
                data: data.subdata(in: messageStart..<recordEnd),
                encoding: .utf8
              ) else {
            return .invalid(consumedBytes: consumedBytes)
        }

        return .record(
            LogRecord(
                timestamp: timestamp,
                level: level,
                module: module,
                message: message
            ),
            consumedBytes: consumedBytes
        )
    }

    // MARK: - Private Methods

    private func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { bytes in
            data.append(contentsOf: bytes)
        }
    }

    private func byte(from data: Data, offset: Int) -> UInt8 {
        data[data.index(data.startIndex, offsetBy: offset)]
    }

    private func readUInt16(from data: Data, offset: Int) -> UInt16 {
        UInt16(byte(from: data, offset: offset)) |
            (UInt16(byte(from: data, offset: offset + 1)) << 8)
    }

    private func readUInt32(from data: Data, offset: Int) -> UInt32 {
        var value: UInt32 = 0
        for index in 0..<4 {
            value |= UInt32(byte(from: data, offset: offset + index)) << UInt32(index * 8)
        }
        return value
    }

    private func readUInt64(from data: Data, offset: Int) -> UInt64 {
        var value: UInt64 = 0
        for index in 0..<8 {
            value |= UInt64(byte(from: data, offset: offset + index)) << UInt64(index * 8)
        }
        return value
    }
}

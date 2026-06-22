//
//  MockLogger.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

@testable import Windscribe

class MockLogger: FileLogger {
    var logDirectory: URL?

    // Call tracking properties
    var logDCalled = false
    var logICalled = false
    var logECalled = false
    var logWSNetCalled = false
    var lastLogDTag: String?
    var lastLogDMessage: String?
    var lastLogITag: String?
    var lastLogIMessage: String?
    var lastLogETag: String?
    var lastLogEMessage: String?

    // Guards the tracking state so the mock is safe under concurrent logging.
    private let lock = NSLock()

    func getLogData() async throws -> String {
        return "Test Logs"
    }

    func logDeviceInfo() {}

    func logD(_ tag: String, _ message: String) {
        recordD(tag, message)
    }

    func logD(_ tag: String, _ message: String, flushImmediately: Bool) {
        recordD(tag, message)
    }

    func logI(_ tag: String, _ message: String) {
        recordI(tag, message)
    }

    func logI(_ tag: String, _ message: String, flushImmediately: Bool) {
        recordI(tag, message)
    }

    func logE(_ tag: String, _ message: String) {
        recordE(tag, message)
    }

    func logE(_ tag: String, _ message: String, flushImmediately: Bool) {
        recordE(tag, message)
    }

    func logWSNet(_ message: String) {
        lock.withLock { logWSNetCalled = true }
        print("[MOCK LOGGER WSNET] \(message)")
    }

    func logI(_ tag: Any, _ message: String) {
        recordI(String(describing: tag), message)
    }

    func logE(_ tag: Any, _ message: String) {
        recordE(String(describing: tag), message)
    }

    func logD(_ object: Any, _ message: String) {
        recordD(String(describing: object), message)
    }

    private func recordD(_ tag: String, _ message: String) {
        lock.withLock {
            logDCalled = true
            lastLogDTag = tag
            lastLogDMessage = message
        }
        print("[MOCK LOGGER DEBUG] \(tag): \(message)")
    }

    private func recordI(_ tag: String, _ message: String) {
        lock.withLock {
            logICalled = true
            lastLogITag = tag
            lastLogIMessage = message
        }
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    private func recordE(_ tag: String, _ message: String) {
        lock.withLock {
            logECalled = true
            lastLogETag = tag
            lastLogEMessage = message
        }
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    // Test helper method
    func reset() {
        lock.withLock {
            logDCalled = false
            logICalled = false
            logECalled = false
            logWSNetCalled = false
            lastLogDTag = nil
            lastLogDMessage = nil
            lastLogITag = nil
            lastLogIMessage = nil
            lastLogETag = nil
            lastLogEMessage = nil
        }
    }
}

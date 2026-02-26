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

    func getLogData() async throws -> String {
        return "Test Logs"
    }

    func logDeviceInfo() {}

    func logD(_ tag: String, _ message: String) {
        logDCalled = true
        lastLogDTag = tag
        lastLogDMessage = message
        print("[MOCK LOGGER DEBUG] \(tag): \(message)")
    }

    func logD(_ tag: String, _ message: String, flushImmediately: Bool) {
        logDCalled = true
        lastLogDTag = tag
        lastLogDMessage = message
        print("[MOCK LOGGER DEBUG] \(tag): \(message)")
    }

    func logI(_ tag: String, _ message: String) {
        logICalled = true
        lastLogITag = tag
        lastLogIMessage = message
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    func logI(_ tag: String, _ message: String, flushImmediately: Bool) {
        logICalled = true
        lastLogITag = tag
        lastLogIMessage = message
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    func logE(_ tag: String, _ message: String) {
        logECalled = true
        lastLogETag = tag
        lastLogEMessage = message
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    func logE(_ tag: String, _ message: String, flushImmediately: Bool) {
        logECalled = true
        lastLogETag = tag
        lastLogEMessage = message
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    func logWSNet(_ message: String) {
        logWSNetCalled = true
        print("[MOCK LOGGER WSNET] \(message)")
    }

    func logI(_ tag: Any, _ message: String) {
        logICalled = true
        lastLogITag = String(describing: tag)
        lastLogIMessage = message
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    func logE(_ tag: Any, _ message: String) {
        logECalled = true
        lastLogETag = String(describing: tag)
        lastLogEMessage = message
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    func logD(_ object: Any, _ message: String) {
        logDCalled = true
        lastLogDTag = String(describing: object)
        lastLogDMessage = message
        print("[MOCK LOGGER DEBUG] \(object): \(message)")
    }

    // Test helper method
    func reset() {
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

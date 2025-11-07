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

    func getLogData() async throws -> String {
        return "Test Logs"
    }

    func logDeviceInfo() {}

    func logD(_ tag: String, _ message: String) {
        print("[MOCK LOGGER DEBUG] \(tag): \(message)")
    }

    func logD(_ tag: String, _ message: String, flushImmediately: Bool) {
        print("[MOCK LOGGER DEBUG] \(tag): \(message)")
    }

    func logI(_ tag: String, _ message: String) {
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    func logI(_ tag: String, _ message: String, flushImmediately: Bool) {
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    func logE(_ tag: String, _ message: String) {
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    func logE(_ tag: String, _ message: String, flushImmediately: Bool) {
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    func logWSNet(_ message: String) {
        print("[MOCK LOGGER WSNET] \(message)")
    }

    func logI(_ tag: Any, _ message: String) {
        print("[MOCK LOGGER INFO] \(tag): \(message)")
    }

    func logE(_ tag: Any, _ message: String) {
        print("[MOCK LOGGER ERROR] \(tag): \(message)")
    }

    func logD(_ object: Any, _ message: String) {
        print("[MOCK LOGGER DEBUG] \(object): \(message)")
    }
}

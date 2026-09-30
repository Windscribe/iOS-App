//
//  LogStoring.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

protocol LogStoring: Sendable {
    func logI(_ tag: String, _ message: String)
    func logE(_ tag: String, _ message: String)
    func logD(_ tag: String, _ message: String)
    func getLogData() async throws -> String
    func getLogData(for purpose: LogExportPurpose) async throws -> String
}

/// Adapter wrapping the legacy `FileLogger`.
final class LegacyLogStore: LogStoring, Sendable {
    private let legacy: FileLogger

    init(legacy: FileLogger) {
        self.legacy = legacy
    }

    func logI(_ tag: String, _ message: String) {
        legacy.logI(tag, message)
    }

    func logE(_ tag: String, _ message: String) {
        legacy.logE(tag, message)
    }

    func logD(_ tag: String, _ message: String) {
        legacy.logD(tag, message)
    }

    func getLogData() async throws -> String {
        try await legacy.getLogData()
    }

    func getLogData(for purpose: LogExportPurpose) async throws -> String {
        try await legacy.getLogData(for: purpose)
    }
}

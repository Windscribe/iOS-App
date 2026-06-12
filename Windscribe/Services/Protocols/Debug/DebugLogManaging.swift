//
//  DebugLogManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Debug log submission surface.
protocol DebugLogManaging: Sendable {
    /// Sends debug log to the server.
    /// - Parameters:
    ///   - username: The username to associate with the log
    ///   - log: The log data as a string
    /// - Returns: APIMessage response
    func sendDebugLog(username: String, log: String) async throws -> APIMessage
}

/// Adapter wrapping the legacy `APIManager`.
final class LegacyDebugLogManager: DebugLogManaging, Sendable {
    private let legacy: APIManager

    init(legacy: APIManager) {
        self.legacy = legacy
    }

    func sendDebugLog(username: String, log: String) async throws -> APIMessage {
        try await legacy.sendDebugLog(username: username, log: log)
    }
}

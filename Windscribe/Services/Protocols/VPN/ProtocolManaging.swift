//
//  ProtocolManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Protocol switching management surface.
protocol ProtocolManaging: Sendable {
    /// Refreshes the protocol list and optionally reconnects.
    /// - Parameters:
    ///   - shouldReset: Whether to reset the protocol selection
    ///   - shouldReconnect: Whether to reconnect with new protocol
    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async
}

/// Adapter wrapping the legacy `ProtocolManagerType`.
final class LegacyProtocolManager: ProtocolManaging, Sendable {
    private let legacy: ProtocolManagerType

    init(legacy: ProtocolManagerType) {
        self.legacy = legacy
    }

    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async {
        await legacy.refreshProtocols(shouldReset: shouldReset, shouldReconnect: shouldReconnect)
    }
}

//
//  VPNStateProviding.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
@preconcurrency import Combine

/// VPN connection state read surface.
protocol VPNStateProviding: Sendable {
    /// Returns true if VPN is currently connected.
    func isConnected() -> Bool

    /// Debounced VPN status stream, preserving the legacy repository's
    /// configuration-state mapping.
    var statusUpdates: AsyncStream<NEVPNStatus> { get }

    /// Requests a fresh status pull from the legacy state repository.
    func refreshConnectionState()

    /// Forces the current VPN info snapshot back to disconnected.
    func resetToDisconnected()
}

/// Adapter wrapping the legacy `VPNStateRepository`.
final class LegacyVPNStateProvider: VPNStateProviding, Sendable {
    private let legacy: VPNStateRepository

    init(legacy: VPNStateRepository) {
        self.legacy = legacy
    }

    func isConnected() -> Bool {
        legacy.isConnected()
    }

    var statusUpdates: AsyncStream<NEVPNStatus> {
        AsyncStream { continuation in
            let cancellable = legacy.getStatus().sink { status in
                continuation.yield(status)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    func refreshConnectionState() {
        legacy.connectionStateUpdatedTrigger.send(())
    }

    func resetToDisconnected() {
        guard let currentInfo = legacy.vpnInfo.value else { return }
        let updatedInfo = VPNConnectionInfo(
            selectedProtocol: currentInfo.selectedProtocol,
            selectedPort: currentInfo.selectedPort,
            status: .disconnected,
            killSwitch: currentInfo.killSwitch,
            onDemand: currentInfo.onDemand
        )
        legacy.vpnInfo.send(updatedInfo)
    }
}

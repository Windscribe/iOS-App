//
//  VPNConnecting.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

/// Command + status surface for the VPN. Neo features consume `connect`/
/// `disconnect` as `async throws` and watch `statusUpdates` as an
/// `AsyncStream`. Back this with a thin adapter over the legacy
/// `VPNManager` + `VPNStateRepository` until those migrate.
protocol VPNConnecting: Sendable {
    func connect(locationId: String, proto: ProtocolPort) async throws
    func disconnect() async throws

    /// Async stream of VPN connection-state updates, sourced from
    /// `NEVPNStatusDidChange` notifications via the legacy
    /// `VPNStateRepository.vpnInfo` subject. The first emission is the
    /// current state, so callers can drive UI directly off this stream.
    var statusUpdates: AsyncStream<VPNConnectionState> { get }
}

/// Adapter wrapping the legacy `VPNManager` (commands) and
/// `VPNStateRepository` (status surface).
///
/// Lives at the Neo composition seam — created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature.
final class LegacyVPNConnector: VPNConnecting, Sendable {
    private let legacy: VPNManager
    private let stateRepository: VPNStateRepository

    init(legacy: VPNManager, stateRepository: VPNStateRepository) {
        self.legacy = legacy
        self.stateRepository = stateRepository
    }

    func connect(locationId: String, proto: ProtocolPort) async throws {
        // Drain intermediate states; await publisher completion. The live
        // status surface is `statusUpdates`, sourced from `vpnInfo`.
        for try await _ in legacy.connectFromViewModel(locationId: locationId, proto: proto).values {}
    }

    func disconnect() async throws {
        for try await _ in legacy.disconnectFromViewModel().values {}
    }

    var statusUpdates: AsyncStream<VPNConnectionState> {
        let subject = stateRepository.vpnInfo
        return AsyncStream { continuation in
            let cancellable = subject.sink { info in
                continuation.yield(.vpn(info?.status ?? .disconnected))
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

//
//  VPNConnecting.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

/// Command surface for connecting and disconnecting the VPN. The async/await
/// surface Neo features consume; back this with a thin adapter over the
/// legacy `VPNManager` until that manager itself migrates.
///
/// **Scope note:** the connection-status stream lives in M4 (T4.2 —
/// `AsyncStream<VPNConnectionState>` over `NEVPNStatusDidChange`). This
/// protocol is commands-only on purpose.
protocol VPNConnecting: Sendable {
    func connect(locationId: String, proto: ProtocolPort) async throws
    func disconnect() async throws
}

/// Adapter that wraps the legacy `VPNManager` (Combine-based) and exposes
/// the Neo `VPNConnecting` surface.
///
/// Lives at the Neo composition seam — created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature.
final class LegacyVPNConnector: VPNConnecting, @unchecked Sendable {
    // @unchecked until M4's Sendability cleanup marks `VPNManager` directly.
    private let legacy: VPNManager

    init(legacy: VPNManager) {
        self.legacy = legacy
    }

    func connect(locationId: String, proto: ProtocolPort) async throws {
        // Drain intermediate states; await publisher completion. M4 owns the live status stream.
        for try await _ in legacy.connectFromViewModel(locationId: locationId, proto: proto).values {}
    }

    func disconnect() async throws {
        for try await _ in legacy.disconnectFromViewModel().values {}
    }
}

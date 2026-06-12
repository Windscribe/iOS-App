//
//  AntiCensorshipManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Anti-censorship settings management surface.
protocol AntiCensorshipManaging: Sendable {
    /// Current WireGuard unlock parameters available.
    var unlockParams: [UnblockWgParams] { get }

    /// Current protocol tweaks enabled state.
    var useProtocolTweaks: Bool { get }

    /// Current server routing type.
    var serverRoutingType: ServerRoutingType { get }

    /// Current selected WireGuard parameter.
    var selectedWgParam: UnblockWgParams? { get }

    /// Updates stream for protocol tweaks enabled state.
    var useProtocolTweaksUpdates: AsyncStream<Bool> { get }

    /// Updates stream for server routing type changes.
    var serverRoutingTypeUpdates: AsyncStream<ServerRoutingType> { get }

    /// Updates stream for selected WG parameter changes.
    var selectedWgParamUpdates: AsyncStream<UnblockWgParams?> { get }

    /// Sets whether to use protocol tweaks.
    func setUseProtocolTweaks(_ value: Bool)

    /// Sets the server routing type.
    func setServerRoutingType(_ value: ServerRoutingType)

    /// Sets the WireGuard parameter by ID.
    func setWgParameter(withId id: String)
}

/// Adapter wrapping the legacy `AntiCensorshipRepository`.
final class LegacyAntiCensorshipManager: AntiCensorshipManaging, Sendable {
    private let legacy: AntiCensorshipRepository

    init(legacy: AntiCensorshipRepository) {
        self.legacy = legacy
    }

    var unlockParams: [UnblockWgParams] {
        legacy.unlockParams
    }

    var useProtocolTweaks: Bool {
        legacy.useProtocolTweaksSubject.value
    }

    var serverRoutingType: ServerRoutingType {
        legacy.selecteRoutingTypeSubject.value
    }

    var selectedWgParam: UnblockWgParams? {
        legacy.selectedWgParamSubject.value
    }

    var useProtocolTweaksUpdates: AsyncStream<Bool> {
        let subject = legacy.useProtocolTweaksSubject
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var serverRoutingTypeUpdates: AsyncStream<ServerRoutingType> {
        let subject = legacy.selecteRoutingTypeSubject
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var selectedWgParamUpdates: AsyncStream<UnblockWgParams?> {
        let subject = legacy.selectedWgParamSubject
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    func setUseProtocolTweaks(_ value: Bool) {
        legacy.setUseProtocolTweaks(value)
    }

    func setServerRoutingType(_ value: ServerRoutingType) {
        legacy.setServerRoutingType(value)
    }

    func setWgParameter(withId id: String) {
        legacy.setWgParameter(withId: id)
    }
}

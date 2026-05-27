//
//  DeviceAttesting.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Generates DeviceCheck tokens for binding signup events to a physical Apple device.
/// The token is opaque base64, only meaningful to Apple's DeviceCheck servers, and
/// rotates every call — never persist it client-side.
protocol DeviceAttesting: Sendable {
    /// Whether the current device supports DeviceCheck. Returns `false` on simulators,
    /// macOS Catalyst running on unsupported hardware, or jailbroken devices that
    /// have disabled DeviceCheck.
    var isSupported: Bool { get }

    /// Generates a one-shot device attestation token (base64). Throws
    /// `DeviceAttestationError.unsupported` on platforms without DeviceCheck and
    /// `.generationFailed` if Apple's API errors.
    func generateToken() async throws -> String
}

enum DeviceAttestationError: Error, Sendable {
    case unsupported
    case generationFailed(any Error & Sendable)
}

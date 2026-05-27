//
//  DCDeviceAttestation.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import DeviceCheck
import Foundation

/// Production `DeviceAttesting` implementation backed by `DCDevice.current`.
/// Holds no mutable state — `DCDevice` is a singleton managed by the OS.
final class DCDeviceAttestation: DeviceAttesting, Sendable {

    var isSupported: Bool {
        DCDevice.current.isSupported
    }

    func generateToken() async throws -> String {
        guard isSupported else {
            throw DeviceAttestationError.unsupported
        }

        return try await withCheckedThrowingContinuation { continuation in
            DCDevice.current.generateToken { data, error in
                if let error {
                    let sendableError = error as NSError
                    continuation.resume(throwing: DeviceAttestationError.generationFailed(sendableError))
                    return
                }
                guard let data else {
                    continuation.resume(throwing: DeviceAttestationError.unsupported)
                    return
                }
                continuation.resume(returning: data.base64EncodedString())
            }
        }
    }
}

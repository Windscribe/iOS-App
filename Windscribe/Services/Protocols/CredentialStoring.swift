//
//  CredentialStoring.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Read access to the OpenVPN and IKEv2 server credentials, plus async
/// refresh hooks. Backed by a thin adapter over the legacy
/// `CredentialsRepository`.
///
/// **Scope note:** the legacy repository also exposes
/// `selectedServerCredentialsType()` and `updateServerConfig()`; those stay
/// on the legacy interface until a Neo feature needs them.
protocol CredentialStoring: Sendable {
    var openVPNCredentials: ServerCredentialsModel? { get }
    var ikev2Credentials: ServerCredentialsModel? { get }

    func refreshOpenVPNCredentials() async throws
    func refreshIKEv2Credentials() async throws
}

/// Adapter wrapping the legacy `CredentialsRepository`.
final class LegacyCredentialStore: CredentialStoring, Sendable {
    private let legacy: CredentialsRepository

    init(legacy: CredentialsRepository) {
        self.legacy = legacy
    }

    // Legacy property names contain a "Crendentials" typo; Neo surface fixes it.
    var openVPNCredentials: ServerCredentialsModel? { legacy.openVPNCrendentials }
    var ikev2Credentials: ServerCredentialsModel? { legacy.ikev2Crendentials }

    func refreshOpenVPNCredentials() async throws {
        try await legacy.getUpdatedOpenVPNCrendentials()
    }

    func refreshIKEv2Credentials() async throws {
        try await legacy.getUpdatedIKEv2Crendentials()
    }
}

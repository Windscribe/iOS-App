//
//  WireguardConfigRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol WireguardConfigRepository {
    func getCredentials(request: WireguardConfigRequest) async throws
}

struct WireguardConfigRequest: Sendable {
    let attemptId: String
    let forceRefresh: Bool

    init(attemptId: String = UUID().uuidString, forceRefresh: Bool = false) {
        self.attemptId = attemptId
        self.forceRefresh = forceRefresh
    }
}

class WireguardConfigRepositoryImpl: WireguardConfigRepository {
    private let apiCallManager: WireguardAPIManager
    private let logger: FileLogger
    private let fileDatabase: FileDatabase
    private let wgCrendentials: WgCredentials
    private let alertManager: AlertManager?
    private let ipManager: WireguardIPManager
    private let preferences: Preferences
    private var hasConnectedOnceEndpoints: Set<String> = []
    private var lastForcedRefreshAttemptId: String?

    init(apiCallManager: WireguardAPIManager, fileDatabase: FileDatabase, wgCrendentials: WgCredentials, alertManager: AlertManager?, logger: FileLogger, ipManager: WireguardIPManager, preferences: Preferences) {
        self.apiCallManager = apiCallManager
        self.fileDatabase = fileDatabase
        self.wgCrendentials = wgCrendentials
        self.alertManager = alertManager
        self.logger = logger
        self.ipManager = ipManager
        self.preferences = preferences
    }

    func getCredentials(request: WireguardConfigRequest) async throws {
        try await wgInit(request: request)
        try await generateLocalIP(attemptId: request.attemptId)
        try await retrieveTemplateWgConfig(attemptId: request.attemptId)
    }

    private func retrieveTemplateWgConfig(attemptId: String) async throws {
        guard let wgConfig = wgCrendentials.asWgCredentialsString(),
              let data = wgConfig.data(using: .utf8) else {
            logger.logE("WireguardLifecycle", "attempt_id=\(attemptId) stage=config.persisted result=failure reason=incomplete_configuration")
            throw RepositoryError.failedToTemplateWgConfig
        }
        try await fileDatabase.saveFile(data: data, path: FilePaths.wireGuard)
        logger.logI("WireguardLifecycle", "attempt_id=\(attemptId) stage=config.persisted result=success")
    }

    private func wgInit(request: WireguardConfigRequest) async throws {
        let currentEndpoint = self.wgCrendentials.serverEndPoint ?? ""
        let isFirstForServer = !hasConnectedOnceEndpoints.contains(currentEndpoint)
        let needsIPv6Refresh = self.wgCrendentials.needsIPv6InitRefreshForCurrentServer()

        if request.forceRefresh {
            if lastForcedRefreshAttemptId == request.attemptId {
                logger.logI("WireguardLifecycle", "attempt_id=\(request.attemptId) stage=wg_init.decision result=skipped reason=forced_refresh_already_attempted")
                return
            }
            lastForcedRefreshAttemptId = request.attemptId
        }

        let reason: String
        if request.forceRefresh {
            reason = "forced_refresh"
        } else if !self.wgCrendentials.initialized() {
            reason = "not_initialized"
        } else if isFirstForServer {
            reason = "first_endpoint_for_repository"
        } else if needsIPv6Refresh {
            reason = "ipv6_data_missing"
        } else {
            logger.logI("WireguardLifecycle", "attempt_id=\(request.attemptId) stage=wg_init.decision result=skipped reason=cached")
            return
        }

        logger.logI("WireguardLifecycle", "attempt_id=\(request.attemptId) stage=wg_init.decision result=refresh reason=\(reason) key_rotation_requested=false")
        guard let userPublicKey = await self.wgCrendentials.getPublicKey(generateIfMissing: !request.forceRefresh),
              !userPublicKey.isEmpty else {
            logger.logE("WireguardLifecycle", "attempt_id=\(request.attemptId) stage=wg_init.result result=failure reason=public_key_unavailable")
            throw RepositoryError.ipGenerationFailed("Public key not available")
        }

        do {
            let config: DynamicWireGuardConfig
            do {
                config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: false)
            } catch let error as Errors where error == .wgLimitExceeded {
                config = try await retryAfterKeyLimit(userPublicKey: userPublicKey, error: error)
            }
            saveSuccessfulInit(config: config, endpoint: currentEndpoint, attemptId: request.attemptId)
        } catch {
            logger.logE("WireguardLifecycle", "attempt_id=\(request.attemptId) stage=wg_init.result result=failure error_type=\(String(describing: type(of: error)))")
            throw error
        }
    }

    private func retryAfterKeyLimit(userPublicKey: String, error: Errors) async throws -> DynamicWireGuardConfig {
        if let alertManager {
            let accept = await alertManager.askUser(message: error.description, title: TextsAsset.note)
            guard accept else { throw Errors.handled }
        }
        return try await apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: true)
    }

    private func saveSuccessfulInit(config: DynamicWireGuardConfig, endpoint: String, attemptId: String) {
        wgCrendentials.saveInitResponse(config: config)
        hasConnectedOnceEndpoints.insert(endpoint)
        logger.logI("WireguardLifecycle", "attempt_id=\(attemptId) stage=wg_init.result result=success key_rotation_requested=false")
    }

    private func generateLocalIP(attemptId: String) async throws {
        // Get CIDR from wgInit response
        guard let initResponse = wgCrendentials.getWgInitResponse(),
              let hashedCIDR = initResponse.hashedCIDR,
              let firstCIDR = hashedCIDR.first else {
            logger.logE("WireguardConfigRepository", "Missing hashedCIDR from wgInit response")
            throw RepositoryError.missingHashedCIDR
        }

        // Get public key
        guard let publicKey = await wgCrendentials.getPublicKey(generateIfMissing: false) else {
            logger.logE("WireguardConfigRepository", "Missing public key for IP generation")
            throw RepositoryError.ipGenerationFailed("Public key not available")
        }

        // Generate IP using first CIDR
        do {
            let generatedIP = try ipManager.generateIP(publicKeyBase64: publicKey, cidr: firstCIDR)
            let dns = "10.255.255.1"

            logger.logI("WireguardLifecycle", "attempt_id=\(attemptId) stage=local_ip.generated family=ipv4 result=success")

            // Generate IPv6 address if server supports it, egress is "Auto", and v6 CIDR is available
            var generatedIPv6: String?
            let expectsIPv6 = wgCrendentials.expectsIPv6ForCurrentServer()
            if expectsIPv6 {
                if let hashedCIDRv6 = initResponse.hashedCIDRv6,
                   let firstCIDRv6 = hashedCIDRv6.first,
                   !firstCIDRv6.isEmpty {
                    do {
                        let v6 = try ipManager.generateIPv6(publicKeyBase64: publicKey, cidr: firstCIDRv6)
                        if v6.isEmpty {
                            logger.logE("WireguardConfigRepository", "IPv6 generation returned empty string for CIDR \(firstCIDRv6); falling back to IPv4-only")
                        } else {
                            generatedIPv6 = v6
                            logger.logI("WireguardLifecycle", "attempt_id=\(attemptId) stage=local_ip.generated family=ipv6 result=success")
                        }
                    } catch {
                        logger.logE("WireguardConfigRepository", "IPv6 expected but generation failed; falling back to IPv4-only: \(error.localizedDescription)")
                    }
                } else {
                    logger.logE("WireguardConfigRepository", "IPv6 expected for current server but hashedCIDRv6 missing/empty from wgInit response; falling back to IPv4-only")
                }
            }

            // Save generated IP and DNS
            wgCrendentials.saveGeneratedIP(ip: generatedIP, dns: dns, ipV6: generatedIPv6)
        } catch {
            logger.logE("WireguardConfigRepository", "Failed to generate IP: \(error.localizedDescription)")
            throw RepositoryError.ipGenerationFailed(error.localizedDescription)
        }
    }

}

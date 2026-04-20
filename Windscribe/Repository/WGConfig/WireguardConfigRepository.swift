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
    func getCredentials() async throws
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

    init(apiCallManager: WireguardAPIManager, fileDatabase: FileDatabase, wgCrendentials: WgCredentials, alertManager: AlertManager?, logger: FileLogger, ipManager: WireguardIPManager, preferences: Preferences) {
        self.apiCallManager = apiCallManager
        self.fileDatabase = fileDatabase
        self.wgCrendentials = wgCrendentials
        self.alertManager = alertManager
        self.logger = logger
        self.ipManager = ipManager
        self.preferences = preferences
    }

    func getCredentials() async throws {
        try await wgInit()
        try await generateLocalIP()
        try await retrieveTemplateWgConfig()
    }

    private func retrieveTemplateWgConfig() async throws {
        guard let wgConfig = wgCrendentials.asWgCredentialsString(),
              let data = wgConfig.data(using: .utf8) else {
            throw RepositoryError.failedToTemplateWgConfig
        }
        try await fileDatabase.saveFile(data: data, path: FilePaths.wireGuard)
    }

    private func wgInit() async throws {
        let currentEndpoint = self.wgCrendentials.serverEndPoint ?? ""
        let isFirstForServer = !hasConnectedOnceEndpoints.contains(currentEndpoint)
        guard !self.wgCrendentials.initialized() || (self.wgCrendentials.initialized() && isFirstForServer) else {
            return
        }
        hasConnectedOnceEndpoints.insert(currentEndpoint)
        let userPublicKey = await self.wgCrendentials.getPublicKey() ?? ""

        do {
            let config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: false)
            self.wgCrendentials.saveInitResponse(config: config)
        } catch let error as Errors where error == .wgLimitExceeded {
            guard let alertManager = self.alertManager  else {
                let config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: true)
                self.wgCrendentials.saveInitResponse(config: config)
                return
            }
            let accept = await alertManager.askUser(message: error.description, title: TextsAsset.note)
            guard accept else { throw Errors.handled }

            let config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: true)
            self.wgCrendentials.saveInitResponse(config: config)
        }
    }

    private func generateLocalIP() async throws {
        // Get CIDR from wgInit response
        guard let initResponse = wgCrendentials.getWgInitResponse(),
              let hashedCIDR = initResponse.hashedCIDR,
              let firstCIDR = hashedCIDR.first else {
            logger.logE("WireguardConfigRepository", "Missing hashedCIDR from wgInit response")
            throw RepositoryError.missingHashedCIDR
        }

        // Get public key
        guard let publicKey = await wgCrendentials.getPublicKey() else {
            logger.logE("WireguardConfigRepository", "Missing public key for IP generation")
            throw RepositoryError.ipGenerationFailed("Public key not available")
        }

        // Generate IP using first CIDR
        do {
            let generatedIP = try ipManager.generateIP(publicKeyBase64: publicKey, cidr: firstCIDR)
            let dns = "10.255.255.1"

            logger.logI("WireguardConfigRepository", "Generated IP: \(generatedIP) from CIDR: \(firstCIDR)")

            // Generate IPv6 address if server supports it, egress is "Auto", and v6 CIDR is available
            var generatedIPv6: String?
            let egressPref = preferences.getEgressProtocolPreferenceSync()
            if wgCrendentials.serverSupportsIPv6,
               egressPref == Fields.Values.auto,
               let hashedCIDRv6 = initResponse.hashedCIDRv6,
               let firstCIDRv6 = hashedCIDRv6.first {
                do {
                    generatedIPv6 = try ipManager.generateIPv6(publicKeyBase64: publicKey, cidr: firstCIDRv6)
                    logger.logI("WireguardConfigRepository", "Generated IPv6: \(generatedIPv6!) from CIDR: \(firstCIDRv6)")
                } catch {
                    logger.logE("WireguardConfigRepository", "Failed to generate IPv6: \(error.localizedDescription)")
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

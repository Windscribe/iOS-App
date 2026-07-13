//
//  EmergencyConnecting.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@preconcurrency import Combine

/// Emergency Connect command surface for Neo authentication screens.
protocol EmergencyConnecting: Sendable {
    func getConfig() async -> [OpenVPNConnectionInfo]
    func connect(configInfo: OpenVPNConnectionInfo) async throws
    func disconnect() async throws
    func isConnected() -> Bool
    func cleanEmergencyConfigs()

    func checkEmergencyConnectCleaning() async -> Bool
}

/// Adapter wrapping the legacy `EmergencyRepository`.
final class LegacyEmergencyConnector: EmergencyConnecting, @unchecked Sendable {
    private let legacy: EmergencyRepository
    private let logger: FileLogger

    init(legacy: EmergencyRepository, logger: FileLogger) {
        self.legacy = legacy
        self.logger = logger
    }

    func getConfig() async -> [OpenVPNConnectionInfo] {
        await legacy.getConfig()
    }

    func connect(configInfo: OpenVPNConnectionInfo) async throws {
        for try await _ in legacy.connect(configInfo: configInfo).values {}
    }

    func disconnect() async throws {
        for try await _ in legacy.disconnect().values {}
    }

    func isConnected() -> Bool {
        legacy.isConnected()
    }

    func cleanEmergencyConfigs() {
        legacy.cleansEmergencyConfigs()
    }

    func checkEmergencyConnectCleaning() async -> Bool {
        let wasEmergencyConnected = isConnected()
        cleanEmergencyConfigs()
        guard wasEmergencyConnected else {
            return false
        }
        logger.logI("LoginViewModel", "Disconnecting emergency connect.")
        try? await disconnect()
        return true
    }
}

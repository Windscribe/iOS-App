//
//  WireguardAPIManagerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol WireguardAPIManager {
    func getSession() async throws -> Session
    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) async throws -> DynamicWireGuardConfig
    func wgConfigConnect(clientPublicKey: String, hostname: String, deviceId: String) async throws -> DynamicWireGuardConnect
}

class WireguardAPIManagerImpl: WireguardAPIManager {
    private let api: WSNetServerAPI
    private let preferences: Preferences
    private let apiUtil: APIUtilService
    init(api: WSNetServerAPI, preferences: Preferences, apiUtil: APIUtilService) {
        self.api = api
        self.preferences = preferences
        self.apiUtil = apiUtil
    }

    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) async throws -> DynamicWireGuardConfig {
        guard let sessionAuth = preferences.userSessionAuth() else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: DynamicWireGuardConfig.self) { [weak self] completion in
            self?.api.wgConfigsInit(sessionAuth, clientPublicKey: clientPublicKey, deleteOldestKey: deleteOldestKey, callback: completion)
        }
    }

    func wgConfigConnect(clientPublicKey: String, hostname: String, deviceId: String) async throws -> DynamicWireGuardConnect {
        guard let sessionAuth = preferences.userSessionAuth() else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: DynamicWireGuardConnect.self) { [weak self] completion in
            self?.api.wgConfigsConnect(sessionAuth, clientPublicKey: clientPublicKey, hostname: hostname, deviceId: deviceId, wgTtl: "3600", callback: completion)
        }
    }

    func getSession() async throws -> Session {
        guard let sessionAuth = preferences.userSessionAuth() else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: Session.self) { completion in
            self.api.session(sessionAuth, appleId: "", gpDeviceId: "", callback: completion)
        }
    }
}

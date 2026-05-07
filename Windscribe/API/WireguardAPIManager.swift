//
//  WireguardAPIManagerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol WireguardAPIManager {
    func getSession() async throws -> SessionModel
    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) async throws -> DynamicWireGuardConfig
}

class WireguardAPIManagerImpl: WireguardAPIManager {
    private let api: WSNetServerAPIType
    private let preferences: Preferences
    private let apiUtil: APIUtilService
    init(api: WSNetServerAPIType, preferences: Preferences, apiUtil: APIUtilService) {
        self.api = api
        self.preferences = preferences
        self.apiUtil = apiUtil
    }

    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) async throws -> DynamicWireGuardConfig {
        guard let sessionAuth = preferences.getSessionAuthHash() else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: DynamicWireGuardConfig.self) { [weak self] completion in
            self?.api.wgConfigsInit(sessionAuth, clientPublicKey: clientPublicKey, deleteOldestKey: deleteOldestKey, callback: completion)
        }
    }

    func getSession() async throws -> SessionModel {
        guard let sessionAuth = preferences.getSessionAuthHash() else {
            throw Errors.validationFailure
        }
        let revision = preferences.getServerRevision()
        let useBackup = preferences.getRoutingType().apiValue
        return try await apiUtil.makeApiCall(modalType: SessionModel.self) { completion in
            self.api.session(sessionAuth, appleId: "", gpDeviceId: "", invRev: revision, backup: useBackup, callback: completion)
        }
    }
}

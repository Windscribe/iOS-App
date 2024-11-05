//
//  WireguardAPIManagerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class WireguardAPIManagerImpl: WireguardAPIManager {
    private let api: WSNetServerAPI
    private let preferences: Preferences
    init(api: WSNetServerAPI, preferences: Preferences) {
        self.api = api
        self.preferences = preferences
    }

    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) -> RxSwift.Single<DynamicWireGuardConfig> {
        guard let sessionAuth = preferences.userSessionAuth() else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: DynamicWireGuardConfig.self) { completion in
            self.api.wgConfigsInit(sessionAuth, clientPublicKey: clientPublicKey, deleteOldestKey: deleteOldestKey, callback: completion)
        }
    }

    func wgConfigConnect(clientPublicKey: String, hostname: String, deviceId: String) -> RxSwift.Single<DynamicWireGuardConnect> {
        guard let sessionAuth = preferences.userSessionAuth() else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: DynamicWireGuardConnect.self) { completion in
            self.api.wgConfigsConnect(sessionAuth, clientPublicKey: clientPublicKey, hostname: hostname, deviceId: deviceId, wgTtl: "3600", callback: completion)
        }
    }

    func getSession() -> Single<Session> {
        guard let sessionAuth = preferences.userSessionAuth() else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: Session.self) { completion in
            self.api.session(sessionAuth, appleId: "", gpDeviceId: "", callback: completion)
        }
    }
}

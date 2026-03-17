//
//  MockWireguardAPIManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockWireguardAPIManager: WireguardAPIManager {
    var wgConfigInitCalled = false
    var wgConfigInitCallCount = 0
    var lastClientPublicKey: String?
    var lastDeleteOldestKey: Bool?
    var wgInitResponseToReturn: DynamicWireGuardConfig?
    var shouldThrowError = false
    var shouldThrowLimitExceeded = false
    var customError: Error?

    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) async throws -> DynamicWireGuardConfig {
        wgConfigInitCalled = true
        wgConfigInitCallCount += 1
        lastClientPublicKey = clientPublicKey
        lastDeleteOldestKey = deleteOldestKey

        if shouldThrowLimitExceeded && wgConfigInitCallCount == 1 {
            throw Errors.wgLimitExceeded
        }

        if shouldThrowError {
            throw customError ?? Errors.notDefined
        }

        guard let response = wgInitResponseToReturn else {
            throw Errors.notDefined
        }

        return response
    }

    func getSession() async throws -> SessionModel {
        // Not needed for these tests
        throw Errors.notDefined
    }

    func reset() {
        wgConfigInitCalled = false
        wgConfigInitCallCount = 0
        lastClientPublicKey = nil
        lastDeleteOldestKey = nil
        wgInitResponseToReturn = nil
        shouldThrowError = false
        shouldThrowLimitExceeded = false
        customError = nil
    }
}

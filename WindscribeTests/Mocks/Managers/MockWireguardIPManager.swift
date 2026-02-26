//
//  MockWireguardIPManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockWireguardIPManager: WireguardIPManager {
    var generateIPCalled = false
    var lastPublicKey: String?
    var lastCIDR: String?
    var generatedIPToReturn: String?
    var shouldThrowError = false

    func generateIP(publicKeyBase64: String, cidr: String) throws -> String {
        generateIPCalled = true
        lastPublicKey = publicKeyBase64
        lastCIDR = cidr

        if shouldThrowError {
            throw NSError(domain: "MockWireguardIPManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock IP generation failed"])
        }

        return generatedIPToReturn ?? "10.64.1.1"
    }

    func reset() {
        generateIPCalled = false
        lastPublicKey = nil
        lastCIDR = nil
        generatedIPToReturn = nil
        shouldThrowError = false
    }
}

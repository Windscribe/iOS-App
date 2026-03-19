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
    var generateIPv6Called = false
    var lastPublicKey: String?
    var lastCIDR: String?
    var generatedIPToReturn: String?
    var generatedIPv6ToReturn: String?
    var shouldThrowError = false
    var shouldThrowIPv6Error = false

    func generateIP(publicKeyBase64: String, cidr: String) throws -> String {
        generateIPCalled = true
        lastPublicKey = publicKeyBase64
        lastCIDR = cidr

        if shouldThrowError {
            throw NSError(domain: "MockWireguardIPManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock IP generation failed"])
        }

        return generatedIPToReturn ?? "10.64.1.1"
    }

    func generateIPv6(publicKeyBase64: String, cidr: String) throws -> String {
        generateIPv6Called = true

        if shouldThrowIPv6Error {
            throw NSError(domain: "MockWireguardIPManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock IPv6 generation failed"])
        }

        return generatedIPv6ToReturn ?? "fd54:4:0:0:1234:5678:abcd:ef01"
    }

    func reset() {
        generateIPCalled = false
        generateIPv6Called = false
        lastPublicKey = nil
        lastCIDR = nil
        generatedIPToReturn = nil
        generatedIPv6ToReturn = nil
        shouldThrowError = false
        shouldThrowIPv6Error = false
    }
}

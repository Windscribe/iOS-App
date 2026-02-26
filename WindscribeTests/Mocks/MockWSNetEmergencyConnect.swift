//
//  MockWSNetEmergencyConnect.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 13/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

/// Mock implementation of WSNetEmergencyConnect for testing
/// Since WSNetEmergencyConnect is an Objective-C class, this mock provides a Swift-based testing alternative
class MockWSNetEmergencyConnect: WSNetEmergencyConnectType {
    private var ipEndpoints: [WSNetEmergencyConnectEndpoint] = []
    private var username: String = ""
    private var password: String = ""
    private var ovpnConfig: String = ""

    func getIpEndpoints() async -> [WSNetEmergencyConnectEndpoint] {
        return ipEndpoints
    }

    func getUsername() -> String {
        return username
    }

    func getPassword() -> String {
        return password
    }

    func getOvpnConfig() -> String {
        return ovpnConfig
    }

    // Setters for testing
    func setIpEndpoints(_ endpoints: [WSNetEmergencyConnectEndpoint]) {
        self.ipEndpoints = endpoints
    }

    func setUsername(_ username: String) {
        self.username = username
    }

    func setPassword(_ password: String) {
        self.password = password
    }

    func setOvpnConfig(_ config: String) {
        self.ovpnConfig = config
    }
}

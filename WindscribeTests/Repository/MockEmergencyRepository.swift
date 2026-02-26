//
//  MockEmergencyRepository.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockEmergencyRepository: EmergencyRepository {

    // Mock Configuration
    var mockConfigs: [OpenVPNConnectionInfo] = []
    var mockIsConnected = false
    var mockConnectionState: VPNConnectionState = .vpn(.disconnected)

    var shouldFailConnect = false
    var shouldFailDisconnect = false
    var errorToThrow: Error = Errors.notDefined

    // Tracking
    var getConfigCalled = false
    var connectCalled = false
    var disconnectCalled = false
    var isConnectedCalled = false
    var cleansEmergencyConfigsCalled = false
    var lastConnectedConfigInfo: OpenVPNConnectionInfo?

    // EmergencyRepository Implementation

    func getConfig() async -> [OpenVPNConnectionInfo] {
        getConfigCalled = true
        return mockConfigs
    }

    func connect(configInfo: OpenVPNConnectionInfo) -> AnyPublisher<VPNConnectionState, Error> {
        connectCalled = true
        lastConnectedConfigInfo = configInfo

        if shouldFailConnect {
            return Fail(error: errorToThrow).eraseToAnyPublisher()
        }

        return Just(mockConnectionState)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func disconnect() -> AnyPublisher<VPNConnectionState, Error> {
        disconnectCalled = true

        if shouldFailDisconnect {
            return Fail(error: errorToThrow).eraseToAnyPublisher()
        }

        return Just(.vpn(.disconnected))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func isConnected() -> Bool {
        isConnectedCalled = true
        return mockIsConnected
    }

    func cleansEmergencyConfigs() {
        cleansEmergencyConfigsCalled = true
    }

    // MARK: Helper Methods

    func reset() {
        mockConfigs = []
        mockIsConnected = false
        mockConnectionState = .vpn(.disconnected)
        shouldFailConnect = false
        shouldFailDisconnect = false
        errorToThrow = Errors.notDefined
        getConfigCalled = false
        connectCalled = false
        disconnectCalled = false
        isConnectedCalled = false
        cleansEmergencyConfigsCalled = false
        lastConnectedConfigInfo = nil
    }
}

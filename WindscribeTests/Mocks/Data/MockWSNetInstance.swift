//
//  MockWSNetInstance.swift
//  WindscribeTests
//
//  Created by Windscribe on 2026-06-23.
//  Copyright © 2026 Windscribe. All rights reserved.
//

@testable import Windscribe

class MockWSNetInstance: WSNetInstanceType {
    var setIsConnectedToVpnStateCalled = false
    var lastIsConnectedToVpnState: Bool?

    var currentPersistentSettingsCalled = false
    var mockPersistentSettings: String = ""

    func setIsConnectedToVpnState(_ isConnected: Bool) {
        setIsConnectedToVpnStateCalled = true
        lastIsConnectedToVpnState = isConnected
    }

    func currentPersistentSettings() -> String {
        currentPersistentSettingsCalled = true
        return mockPersistentSettings
    }

    func reset() {
        setIsConnectedToVpnStateCalled = false
        lastIsConnectedToVpnState = nil
        currentPersistentSettingsCalled = false
        mockPersistentSettings = ""
    }
}

//
//  MockWSNetBridgeAPI.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockWSNetBridgeAPI: WSNetBridgeAPIType {
    private let lock = NSLock()

    // Mock Configuration
    var mockCurrentHost: String = ""
    var mockResult: (Int32, String) = (0, "")
    var mockHasSessionToken: Bool = false
    var mockIgnoreSslErrors: Bool = false
    var mockConnectedState: Bool = false
    private var _mockApiAvailableCallback: ((Bool) -> Void)?
    var mockApiAvailableCallback: ((Bool) -> Void)? {
        get { lock.withLock { _mockApiAvailableCallback } }
        set { lock.withLock { _mockApiAvailableCallback = newValue } }
    }

    // Tracking
    var setCurrentHostCalled = false
    var setIgnoreSslErrorsCalled = false
    var setConnectedStateCalled = false
    private var _setApiAvailableCallbackCalled = false
    var setApiAvailableCallbackCalled: Bool {
        get { lock.withLock { _setApiAvailableCallbackCalled } }
        set { lock.withLock { _setApiAvailableCallbackCalled = newValue } }
    }
    var rotateIPCalled = false
    var pinIpCalled = false
    var hasSessionTokenCalled = false

    var lastCurrentHost: String?
    var lastIgnoreSslErrors: Bool?
    var lastConnectedState: Bool?

    var setCurrentHostCallCount = 0
    var setIgnoreSslErrorsCallCount = 0
    var setConnectedStateCallCount = 0

    // WSNetBridgeAPI Implementation

    func setCurrentHost(_ host: String) {
        setCurrentHostCalled = true
        setCurrentHostCallCount += 1
        lastCurrentHost = host
        mockCurrentHost = host
    }

    func setIgnoreSslErrors(_ ignore: Bool) {
        setIgnoreSslErrorsCalled = true
        setIgnoreSslErrorsCallCount += 1
        lastIgnoreSslErrors = ignore
        mockIgnoreSslErrors = ignore
    }

    func setConnectedState(_ connected: Bool) {
        setConnectedStateCalled = true
        setConnectedStateCallCount += 1
        lastConnectedState = connected
        mockConnectedState = connected
    }

    func setApiAvailableCallback(_ callback: @escaping (Bool) -> Void) {
        lock.withLock {
            _setApiAvailableCallbackCalled = true
            _mockApiAvailableCallback = callback
        }
    }

    func hasSessionToken() -> Bool {
        hasSessionTokenCalled = true
        return mockHasSessionToken
    }

    func rotateIp() async throws -> (Int32, String) {
        rotateIPCalled = true
        return mockResult
    }

    func pinIp(ip: String) async throws -> (Int32, String) {
        pinIpCalled = true
        return mockResult
    }

    // MARK: Helper Methods

    func simulateApiAvailable(_ ready: Bool) {
        let callback = lock.withLock { _mockApiAvailableCallback }
        callback?(ready)
    }

    func reset() {
        mockCurrentHost = ""
        mockResult = (0, "")
        mockHasSessionToken = false
        mockIgnoreSslErrors = false
        mockConnectedState = false
        mockApiAvailableCallback = nil
        setCurrentHostCalled = false
        setIgnoreSslErrorsCalled = false
        setConnectedStateCalled = false
        setApiAvailableCallbackCalled = false
        rotateIPCalled = false
        pinIpCalled = false
        hasSessionTokenCalled = false
        lastCurrentHost = nil
        lastIgnoreSslErrors = nil
        lastConnectedState = nil
        setCurrentHostCallCount = 0
        setIgnoreSslErrorsCallCount = 0
        setConnectedStateCallCount = 0
    }
}

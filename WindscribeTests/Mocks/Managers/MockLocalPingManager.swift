//
//  MockLocalPingManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-02-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockLocalPingManager: LocalPingManager {

    // Mock Configuration

    var mockPingResult: (time: Int32, success: Bool) = (50, true)
    var shouldFail = false
    var customPingResults: [String: (time: Int32, success: Bool)] = [:]

    // Tracking

    var pingCalled = false
    var pingCount = 0
    var lastPingedIP: String?
    var lastPingedHostname: String?
    var lastPingType: Int32?
    var allPingedIPs: [String] = []

    // LocalPingManager Implementation

    func ping(_ ip: String, hostname: String, pingType: Int32) async -> (time: Int32, success: Bool) {
        pingCalled = true
        pingCount += 1
        lastPingedIP = ip
        lastPingedHostname = hostname
        lastPingType = pingType
        allPingedIPs.append(ip)

        // Check for custom result for this specific IP
        if let customResult = customPingResults[ip] {
            return customResult
        }

        // Return failure if shouldFail is true
        if shouldFail {
            return (-1, false)
        }

        // Return default mock result
        return mockPingResult
    }

    // MARK: Helper Methods

    func reset() {
        pingCalled = false
        pingCount = 0
        lastPingedIP = nil
        lastPingedHostname = nil
        lastPingType = nil
        allPingedIPs = []
        shouldFail = false
        mockPingResult = (50, true)
        customPingResults = [:]
    }

    func setCustomResult(for ip: String, time: Int32, success: Bool) {
        customPingResults[ip] = (time, success)
    }
}

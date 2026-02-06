//
//  MockStaticIpRepository.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-02-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockStaticIpRepository: StaticIpRepository {

    // Protocol Properties
    var staticIPs: [StaticIPModel] = []

    // Mock Configuration
    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined
    var mockStaticIPs: [StaticIPModel] = []

    // Tracking
    var updateStaticServersCalled = false
    var getStaticIpIntCalled = false
    var getStaticIpStringCalled = false
    var lastQueriedId: String?

    func updateStaticServers() async throws {
        updateStaticServersCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        staticIPs = mockStaticIPs
    }

    func getStaticIp(id: Int) -> StaticIPModel? {
        getStaticIpIntCalled = true
        lastQueriedId = "\(id)"
        return mockStaticIPs.first { $0.id == id }
    }

    func getStaticIp(id: String) -> StaticIPModel? {
        getStaticIpStringCalled = true
        lastQueriedId = id
        guard let intId = Int(id) else { return nil }
        return getStaticIp(id: intId)
    }

    // MARK: Helper Methods

    func reset() {
        updateStaticServersCalled = false
        getStaticIpIntCalled = false
        getStaticIpStringCalled = false
        shouldThrowError = false
        errorToThrow = Errors.notDefined
        staticIPs = []
        mockStaticIPs = []
        lastQueriedId = nil
    }
}

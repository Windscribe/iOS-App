//
//  MockPortMapRepository.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockPortMapRepository: PortMapRepository {

    // Control flags
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockPortMapRepository", code: -1, userInfo: nil)
    var portMapsToReturn: [PortMap] = []

    // Call tracking
    var getUpdatedPortMapCalled = false
    var callCount = 0

    func getUpdatedPortMap() async throws -> [PortMap] {
        getUpdatedPortMapCalled = true
        callCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return portMapsToReturn
    }

    func reset() {
        shouldThrowError = false
        errorToThrow = NSError(domain: "MockPortMapRepository", code: -1, userInfo: nil)
        portMapsToReturn = []
        getUpdatedPortMapCalled = false
        callCount = 0
    }
}

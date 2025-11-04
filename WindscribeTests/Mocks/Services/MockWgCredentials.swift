//
//  MockWgCredentials.swift
//  WindscribeTests
//
//  Created by Claude Code on 2025-10-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockWgCredentials: WgCredentials {
    var deleteCalled = false

    init() {
        // Create mock dependencies
        let mockPreferences = MockPreferences()
        let mockLogger = MockLogger()
        let mockKeychainManager = MockKeychainManager()

        super.init(preferences: mockPreferences, logger: mockLogger, keychainManager: mockKeychainManager)
    }

    override func delete() {
        deleteCalled = true
        super.delete()
    }

    func reset() {
        deleteCalled = false
    }
}

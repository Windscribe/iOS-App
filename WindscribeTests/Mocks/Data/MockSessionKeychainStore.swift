//
//  MockSessionKeychainStore.swift
//  WindscribeTests
//
//  Created by CodeScribe on 2026-04-24.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockSessionKeychainStore: SessionKeychainStore {
    var storedSession: SessionModel?
    var saveCalled = false
    var loadCalled = false
    var clearCalled = false

    func save(session: SessionModel) {
        saveCalled = true
        storedSession = session
    }

    func load() -> SessionModel? {
        loadCalled = true
        return storedSession
    }

    func clear() {
        clearCalled = true
        storedSession = nil
    }
}

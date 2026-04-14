//
//  MockHashAuthManager.swift
//  WindscribeTests
//
//  Created by Anthony on 2026-04-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockHashAuthManager: HashAuthManager {

    @Published private(set) var _accountHash: String = ""
    var accountHash: String { _accountHash }
    var accountHashPublisher: Published<String>.Publisher { $_accountHash }
    var preImageData: Data = Data()

    var regenerateCalled = false
    var regenerateReturnValue = true
    var loadFromFileCalled = false
    var loadedData: Data?
    var copyHashCalled = false
    var mockHashResult = "0xmockhash1234567890abcdef"

    @discardableResult
    func regenerate() -> Bool {
        regenerateCalled = true
        _accountHash = mockHashResult
        return regenerateReturnValue
    }

    func loadFromFile(_ data: Data) {
        loadFromFileCalled = true
        loadedData = data
        preImageData = data
        _accountHash = mockHashResult
    }

    func copyHash() {
        copyHashCalled = true
    }

    func hash(from data: Data) -> String {
        mockHashResult
    }

    func reset() {
        regenerateCalled = false
        loadFromFileCalled = false
        loadedData = nil
        copyHashCalled = false
        _accountHash = ""
        preImageData = Data()
    }
}

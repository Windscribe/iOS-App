//
//  AdvanceRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class AdvanceRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var mockPreferences: MockPreferences!
    var mockVPNStateRepository: MockVPNStateRepository!
    var repository: AdvanceRepository!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPreferences = MockPreferences()
        mockVPNStateRepository = MockVPNStateRepository()

        // Register mock preferences
        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }

        // Register mock VPNManager
        mockContainer.register(VPNStateRepository.self) { _ in
            return self.mockVPNStateRepository
        }

        // Register mock AdvanceRepository for unit tests
        mockContainer.register(AdvanceRepository.self) { _ in
            return AdvanceRepositoryImpl(preferences: self.mockPreferences,
                                         vpnStateRepository: self.mockVPNStateRepository)
        }.inObjectScope(.container)

        repository = mockContainer.resolve(AdvanceRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        repository = nil
        mockVPNStateRepository = nil
        mockPreferences = nil
        super.tearDown()
    }

    // MARK: Advance Repository Tests
    func test_emptyAdvanceRepository() {

        let pingType = repository.getPingType()
        let forcedServer = repository.getForcedServer()

        XCTAssertEqual(pingType, 0, "Fresh Advance Repository PingType should default to 0")
        XCTAssertNil(forcedServer, "Fresh Advance Repository should have no ForcedServer")
    }

    func test_updatePingType() {
        mockPreferences.saveAdvanceParams(params: "\(wsUsesICMPPings)=true")
        var pingType = repository.getPingType()

        XCTAssertEqual(pingType, 1, "Advance Repository PingType should update to 1 if set to true as a string")

        mockPreferences.saveAdvanceParams(params: "\(wsUsesICMPPings)=false")
        pingType = repository.getPingType()

        XCTAssertEqual(pingType, 0, "Advance Repository PingType should update to 0 is set to false as a string")

        mockPreferences.saveAdvanceParams(params: "\(wsUsesICMPPings)=1")
        pingType = repository.getPingType()

        XCTAssertEqual(pingType, 0, "Advance Repository PingType should be 0 if not correctly set as true")

        mockPreferences.saveAdvanceParams(params: "")
        pingType = repository.getPingType()

        XCTAssertEqual(pingType, 0, "Advance Repository PingType should be 0 if not set again")
    }

    func test_updateForcedServer() {
        let inputForcedServer = "192:123:56:90"
        mockPreferences.saveAdvanceParams(params: "\(wsForceNode)=\(inputForcedServer)")
        var forcedServer = repository.getForcedServer()

        XCTAssertEqual(forcedServer, inputForcedServer, "Advance Repository forced server should be updated to the one set")

        mockPreferences.saveAdvanceParams(params: "\(wsForceNode)=canbeanything")
        forcedServer = repository.getForcedServer()

        XCTAssertEqual(forcedServer, "canbeanything", "Advance Repository ForcedServer can be any string")

        mockPreferences.saveAdvanceParams(params: "")
        forcedServer = repository.getForcedServer()

        XCTAssertNil(forcedServer, "Fresh Advance Repository should have no ForcedServer if it reset")
    }
}

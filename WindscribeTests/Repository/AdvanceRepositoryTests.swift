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
        let forcedNode = repository.getForcedNode()
        let countryOverride = repository.getCountryOverride()

        XCTAssertEqual(pingType, 0, "Fresh Advance Repository PingType should default to 0")
        XCTAssertNil(forcedNode, "Fresh Advance Repository should have no ForceNode")
        XCTAssertNil(countryOverride, "Fresh Advance Repository should have no CountryOverride")
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

    func test_updateForceNode() {
        let inputForceNode = "192:123:56:90"
        mockPreferences.saveAdvanceParams(params: "\(wsForceNode)=\(inputForceNode)")
        var forcedNode = repository.getForcedNode()

        XCTAssertEqual(forcedNode, inputForceNode, "Advance Repository force node should be updated to the one set")

        mockPreferences.saveAdvanceParams(params: "\(wsForceNode)=canbeanything")
        forcedNode = repository.getForcedNode()

        XCTAssertEqual(forcedNode, "canbeanything", "Advance Repository ForceNode can be any string")

        mockPreferences.saveAdvanceParams(params: "")
        forcedNode = repository.getForcedNode()

        XCTAssertNil(forcedNode, "Fresh Advance Repository should have no ForceNode if it reset")
    }

    func test_countryOverride() {
        mockPreferences.saveAdvanceParams(params: "\(wsServerOverrride)=\(ignoreCountryOverride)")
        var countryCode = repository.getCountryOverride()

        XCTAssertEqual(countryCode, ignoreCountryCode, "Advance Repository country override should be ignore")

        mockPreferences.saveAdvanceParams(params: "\(wsServerOverrride)=US")
        countryCode = repository.getCountryOverride()

        XCTAssertEqual(countryCode, "US", "Advance Repository country override should be US")

        mockPreferences.saveAdvanceParams(params: "")
        countryCode = repository.getCountryOverride()

        XCTAssertNil(countryCode, "Fresh Advance Repository should have no country override if the param is set as empty")

        mockVPNStateRepository.mockStatus = .connected

        countryCode = repository.getCountryOverride()

        XCTAssertEqual(countryCode, ignoreCountryCode, "Advance Repository country override should be ignore if param is empty but VPN is connected")
    }
}

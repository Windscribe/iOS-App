//
//  MockAdvanceRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

@testable import Windscribe

class MockAdvanceRepository: AdvanceRepository {

    // MARK: - Mock Properties
    var countryOverrideToReturn = "CountryOverride"
    var forcedNodeToReturn = "ForceNode"
    var pingTypeToReturn: Int32 = 0

    // MARK: - AdvanceRepository Implementation

    func getCountryOverride() -> String? {
        countryOverrideToReturn
    }

    func getForcedNode() -> String? {
        forcedNodeToReturn
    }

    func getPingType() -> Int32 {
        return pingTypeToReturn
    }

    // MARK: - Test Helpers

    func reset() {
        countryOverrideToReturn = "CountryOverride"
        forcedNodeToReturn = "ForceNode"
        pingTypeToReturn = 0
    }
}

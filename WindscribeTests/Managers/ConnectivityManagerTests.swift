//
//  ConnectivityManagerTests.swift
//  WindscribeTests
//
//  Created by Codescribe on 2026-05-21.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
@testable import Windscribe

final class ConnectivityManagerTests: XCTestCase {
    func testDebouncesConnectedWifiToCellularHandoff() {
        let previous = AppNetwork(.connected, networkType: .wifi, name: "Wifi A")
        let next = AppNetwork(.connected, networkType: .cellular, name: "Cellular")

        XCTAssertTrue(ConnectivityManagerImpl.shouldDebounceWifiToCellularHandoff(previous: previous, next: next))
    }

    func testDoesNotDebounceConnectedWifiToWifiChange() {
        let previous = AppNetwork(.connected, networkType: .wifi, name: "Wifi A")
        let next = AppNetwork(.connected, networkType: .wifi, name: "Wifi B")

        XCTAssertFalse(ConnectivityManagerImpl.shouldDebounceWifiToCellularHandoff(previous: previous, next: next))
    }

    func testDoesNotDebounceDisconnectedWifiToCellularChange() {
        let previous = AppNetwork(.disconnected, networkType: .wifi, name: "Wifi A")
        let next = AppNetwork(.connected, networkType: .cellular, name: "Cellular")

        XCTAssertFalse(ConnectivityManagerImpl.shouldDebounceWifiToCellularHandoff(previous: previous, next: next))
    }
}

//
//  AppNetworkTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-07-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
@testable import Windscribe

final class AppNetworkTests: XCTestCase {

    func testCellularDisplayNameUsesLocalizedCellularText() {
        let network = AppNetwork(.connected, networkType: .cellular, name: Fields.Values.cellular)

        XCTAssertEqual(network.displayName, TextsAsset.cellular)
    }

    func testCellularDisplayNameIgnoresCarrierSuppliedName() {
        let network = AppNetwork(.connected, networkType: .cellular, name: "Some Carrier")

        XCTAssertEqual(network.displayName, TextsAsset.cellular)
    }

    /// `Free` is also a key in the string tables, so localizing `name` wholesale would translate
    /// this SSID instead of showing it.
    func testWifiDisplayNameIsNotLocalized() {
        let network = AppNetwork(.connected, networkType: .wifi, name: "Free")

        XCTAssertEqual(network.displayName, "Free")
    }

    func testWifiDisplayNamePreservesArbitrarySSID() {
        let network = AppNetwork(.connected, networkType: .wifi, name: "Andre's iPhone")

        XCTAssertEqual(network.displayName, "Andre's iPhone")
    }

    func testDisplayNameIsNilWithoutNetworkType() {
        let network = AppNetwork(.disconnected)

        XCTAssertNil(network.displayName)
    }

    /// `name` is the stored network identity that `WifiNetwork` is keyed on and that
    /// `VPNManager`'s on-demand rules match against, so localizing the label must not change it.
    func testDisplayNameDoesNotMutateStoredName() {
        let cellular = AppNetwork(.connected, networkType: .cellular, name: Fields.Values.cellular)
        _ = cellular.displayName

        XCTAssertEqual(cellular.name, Fields.Values.cellular)
    }

    /// The cellular identity is a fixed untranslated value; the on-demand rules and the
    /// `isNetworkCellularWhileConnecting` checks compare stored SSIDs against it directly.
    func testCellularFieldValueIsNotLocalized() {
        XCTAssertEqual(Fields.Values.cellular, "Cellular")
    }
}

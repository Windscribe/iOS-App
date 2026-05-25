//
//  PreferencesTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class PreferencesTests: XCTestCase {

    var mockContainer: Container!
    private var cancellables = Set<AnyCancellable>()

    // Test constants
    private let advanceParams = "test-advance-params"
    private let testLanguage = "en"
    private let testProtocol = "OpenVPN"
    private let testPort = "443"
    private let testConnectionMode = "auto"

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockContainer.register(Preferences.self) { _ in
            return MockPreferences()
        }.inObjectScope(.container)
    }

    override func tearDown() {
        cancellables.removeAll()
        mockContainer = nil
        super.tearDown()
    }

    func testSaveAdvanceParams() {
        let preferences = mockContainer.resolve(Preferences.self)!
        preferences.saveAdvanceParams(params: advanceParams)

        let expectation = self.expectation(description: "Get advance params")

        preferences.getAdvanceParams()
            .sink { params in
                XCTAssertEqual(params, self.advanceParams)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup
        preferences.saveAdvanceParams(params: "")
    }

    func testLanguagePreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        preferences.saveLanguage(language: testLanguage)

        let expectation = self.expectation(description: "Get language")

        preferences.getLanguage()
            .sink { language in
                XCTAssertEqual(language, self.testLanguage)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup
        preferences.saveLanguage(language: "")
    }

    func testProtocolPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!

        let expectation = self.expectation(description: "Get protocol")

        // Subscribe first, then save to ensure we catch the update
        preferences.getSelectedProtocol()
            .dropFirst() // Drop the initial value (VPNProtocolType.wireGuard.identifier)
            .first() // Only take the first emission after the initial
            .sink { selectedProtocol in
                XCTAssertEqual(selectedProtocol, self.testProtocol)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Now trigger the save
        preferences.saveSelectedProtocol(selectedProtocol: testProtocol)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup
        preferences.saveSelectedProtocol(selectedProtocol: "")
    }

    func testPortPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        preferences.saveSelectedPort(port: testPort)

        let expectation = self.expectation(description: "Get port")

        preferences.getSelectedPort()
            .sink { port in
                XCTAssertEqual(port, self.testPort)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup
        preferences.saveSelectedPort(port: "")
    }

    func testBooleanPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!

        // Test firewall mode
        preferences.saveFirewallMode(firewall: true)
        let firewallExpectation = expectation(description: "Get firewall mode")
        preferences.getFirewallMode()
            .first()
            .sink { firewall in
                XCTAssertEqual(firewall, true)
                firewallExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Test kill switch
        preferences.saveKillSwitch(killSwitch: true)
        let killSwitchExpectation = expectation(description: "Get kill switch")
        preferences.getKillSwitch()
            .first()
            .sink { killSwitch in
                XCTAssertEqual(killSwitch, true)
                killSwitchExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Test dark mode
        preferences.saveDarkMode(darkMode: true)
        let darkModeExpectation = expectation(description: "Get dark mode")
        preferences.getDarkMode()
            .first()
            .sink { darkMode in
                XCTAssertEqual(darkMode, true)
                darkModeExpectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup - reset all boolean preferences to default/false
        preferences.saveFirewallMode(firewall: false)
        preferences.saveKillSwitch(killSwitch: false)
        preferences.saveDarkMode(darkMode: false)
    }

    func testConnectionCount() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let originalCount = preferences.getConnectionCount() ?? 0
        let testCount = 5

        preferences.saveConnectionCount(count: testCount)
        let count = preferences.getConnectionCount() ?? 0
        XCTAssertEqual(count, testCount)

        preferences.increaseConnectionCount()
        let increasedCount = preferences.getConnectionCount() ?? 0
        XCTAssertEqual(increasedCount, testCount + 1)

        // Cleanup - restore original count
        preferences.saveConnectionCount(count: originalCount)
    }

    func testRateUsPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testDate = Date()
        let originalDate = preferences.getWhenRateUsPopupDisplayed()
        let originalCompleted = preferences.getRateUsActionCompleted()

        preferences.saveWhenRateUsPopupDisplayed(date: testDate)
        let retrievedDate = preferences.getWhenRateUsPopupDisplayed()
        XCTAssertNotNil(retrievedDate)
        if let retrievedDate = retrievedDate {
            XCTAssertEqual(retrievedDate.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
        }

        preferences.saveRateUsActionCompleted(bool: true)
        let completed = preferences.getRateUsActionCompleted()
        XCTAssertTrue(completed)

        // Cleanup - restore original values
        if let originalDate = originalDate {
            preferences.saveWhenRateUsPopupDisplayed(date: originalDate)
        }
        preferences.saveRateUsActionCompleted(bool: originalCompleted)
    }

    func testFavouriteIds() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testId = "test-favourite-id"

        let expectation = self.expectation(description: "Observe favourite IDs")

        preferences.observeFavouriteIds()
            .sink { ids in
                if ids.contains(testId) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        preferences.addFavouriteId(testId)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup - remove the test ID and clear all favourites
        preferences.removeFavouriteId(testId)
        preferences.clearFavourites()
    }

    func testSyncMethods() {
        let preferences = mockContainer.resolve(Preferences.self)!

        // These are read-only methods in the mock
        XCTAssertFalse(preferences.getKillSwitchSync())
        XCTAssertFalse(preferences.getAllowLaneSync())

        // getConnectionModeSync returns the default value from mockConnectionMode
        let connectionMode = preferences.getConnectionModeSync()
        XCTAssertEqual(connectionMode, Fields.Values.manual, "Connection mode should default to manual")

        // For protocol and port sync methods, the non-optional versions return ""
        // Note: Swift may resolve to either the String or String? version depending on context
        let protocolSync: String = preferences.getSelectedProtocolSync()
        XCTAssertEqual(protocolSync, "", "Non-optional getSelectedProtocolSync should return empty string")

        let portSync: String = preferences.getSelectedPortSync()
        XCTAssertEqual(portSync, "", "Non-optional getSelectedPortSync should return empty string")
    }

    func testIPStackDefaultsToAuto() {
        let preferences = mockContainer.resolve(Preferences.self)!

        let egressExpectation = expectation(description: "Default egress IP stack")
        preferences.getEgressProtocolPreference()
            .first()
            .sink { preference in
                XCTAssertEqual(preference, DefaultValues.ipStack)
                egressExpectation.fulfill()
            }
            .store(in: &cancellables)

        let ingressExpectation = expectation(description: "Default ingress IP stack")
        preferences.getIngressProtocolPreference()
            .first()
            .sink { preference in
                XCTAssertEqual(preference, DefaultValues.ipStack)
                ingressExpectation.fulfill()
            }
            .store(in: &cancellables)

        XCTAssertEqual(preferences.getEgressProtocolPreferenceSync(), DefaultValues.ipStack)
        XCTAssertEqual(preferences.getIngressProtocolPreferenceSync(), DefaultValues.ipStack)
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testLocationPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testLocationId = "test-location-123"
        let originalLastLocation = preferences.getLastConnectionTarget()
        let originalBestLocation = preferences.getBestLocation()

        preferences.saveLastConnectionTarget(with: testLocationId)
        let lastLocation = preferences.getLastConnectionTarget()
        XCTAssertEqual(lastLocation, testLocationId)

        preferences.saveBestLocation(with: testLocationId)
        let bestLocation = preferences.getBestLocation()
        XCTAssertEqual(bestLocation, testLocationId)

        // Cleanup - restore original values
        preferences.saveLastConnectionTarget(with: originalLastLocation)
        preferences.saveBestLocation(with: originalBestLocation)
        preferences.clearSelectedLocations()
    }

    func testIpAddressPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testIpAddress = "192.168.1.100"
        let originalIpAddress = preferences.getCurrentIpAddress()

        // Test synchronous save and get
        preferences.saveCurrentIpAddress(ip: testIpAddress)
        let retrievedIp = preferences.getCurrentIpAddress()
        XCTAssertEqual(retrievedIp, testIpAddress, "IP address should be saved and retrieved correctly")

        // Test observable
        let expectation = self.expectation(description: "Get IP address via observable")
        preferences.getCurrentIpAddressObservable()
            .first()
            .sink { ip in
                XCTAssertEqual(ip, testIpAddress, "Observable should emit the saved IP address")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Cleanup - restore original value
        preferences.saveCurrentIpAddress(ip: originalIpAddress)
    }

    func testIpAddressObservableUpdates() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testIpAddress1 = "10.0.0.1"
        let testIpAddress2 = "10.0.0.2"

        var receivedIps: [String?] = []
        let expectation = self.expectation(description: "Observe multiple IP address updates")

        // Subscribe to observable and collect first 3 emissions
        preferences.getCurrentIpAddressObservable()
            .prefix(3)
            .collect()
            .sink { ips in
                receivedIps = ips
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger updates
        preferences.saveCurrentIpAddress(ip: testIpAddress1)
        preferences.saveCurrentIpAddress(ip: testIpAddress2)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Verify received values
        XCTAssertEqual(receivedIps.count, 3, "Should receive initial nil and 2 updates")
        XCTAssertNil(receivedIps[0], "First value should be nil (initial)")
        XCTAssertEqual(receivedIps[1], testIpAddress1, "Second value should be first IP")
        XCTAssertEqual(receivedIps[2], testIpAddress2, "Third value should be second IP")

        // Cleanup
        preferences.saveCurrentIpAddress(ip: nil)
    }

    func testIpAddressNilHandling() {
        let preferences = mockContainer.resolve(Preferences.self)!

        // Save a value first
        preferences.saveCurrentIpAddress(ip: "192.168.1.1")
        XCTAssertNotNil(preferences.getCurrentIpAddress())

        // Test clearing by setting to nil
        preferences.saveCurrentIpAddress(ip: nil)
        let clearedIp = preferences.getCurrentIpAddress()
        XCTAssertNil(clearedIp, "IP address should be nil after clearing")

        // Verify observable also emits nil
        let expectation = self.expectation(description: "Observable should emit nil")
        preferences.getCurrentIpAddressObservable()
            .first()
            .sink { ip in
                XCTAssertNil(ip, "Observable should emit nil after clearing")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCustomAppIconPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testIconValue = "Mail"
        let originalIcon = preferences.getCustomAppIcon()

        // Test saving and retrieving custom app icon
        preferences.saveCustomAppIcon(value: testIconValue)
        let retrievedIcon = preferences.getCustomAppIcon()
        XCTAssertEqual(retrievedIcon, testIconValue, "Custom app icon should be saved and retrieved correctly")

        // Test with different icon value
        let testIconValue2 = "Calendar"
        preferences.saveCustomAppIcon(value: testIconValue2)
        let retrievedIcon2 = preferences.getCustomAppIcon()
        XCTAssertEqual(retrievedIcon2, testIconValue2, "Updated app icon should be retrieved correctly")

        // Cleanup - restore original value or clear
        if let originalIcon = originalIcon {
            preferences.saveCustomAppIcon(value: originalIcon)
        }
    }

    func testCustomAppIconDefaultValue() {
        let preferences = mockContainer.resolve(Preferences.self)!

        // When no icon is saved, it should return nil (meaning use default)
        let icon = preferences.getCustomAppIcon()
        XCTAssertNil(icon, "Custom app icon should be nil when not set, indicating default icon")
    }

    func testCustomAppIconAllValues() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let iconValues = ["Default", "Mail", "Calendar", "Weather", "Notes", "Calculator"]

        // Test each icon value
        for iconValue in iconValues {
            preferences.saveCustomAppIcon(value: iconValue)
            let retrieved = preferences.getCustomAppIcon()
            XCTAssertEqual(retrieved, iconValue, "Icon value '\(iconValue)' should be saved and retrieved correctly")
        }

        // Cleanup
        preferences.saveCustomAppIcon(value: "Default")
    }
}

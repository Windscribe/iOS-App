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
        preferences.saveSelectedProtocol(selectedProtocol: testProtocol)

        let expectation = self.expectation(description: "Get protocol")

        preferences.getSelectedProtocol()
            .sink { selectedProtocol in
                XCTAssertEqual(selectedProtocol, self.testProtocol)
                expectation.fulfill()
            }
            .store(in: &cancellables)

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
            .sink { firewall in
                XCTAssertEqual(firewall, true)
                firewallExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Test kill switch
        preferences.saveKillSwitch(killSwitch: true)
        let killSwitchExpectation = expectation(description: "Get kill switch")
        preferences.getKillSwitch()
            .sink { killSwitch in
                XCTAssertEqual(killSwitch, true)
                killSwitchExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Test dark mode
        preferences.saveDarkMode(darkMode: true)
        let darkModeExpectation = expectation(description: "Get dark mode")
        preferences.getDarkMode()
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

        // These are read-only methods in the mock, so no cleanup needed
        XCTAssertFalse(preferences.getKillSwitchSync())
        XCTAssertFalse(preferences.getAllowLaneSync())
        XCTAssertEqual(preferences.getPingMethodSync(), "")
        XCTAssertEqual(preferences.getConnectionModeSync(), "")
        XCTAssertEqual(preferences.getSelectedProtocolSync(), "")
        XCTAssertEqual(preferences.getSelectedPortSync(), "")
    }

    func testLocationPreferences() {
        let preferences = mockContainer.resolve(Preferences.self)!
        let testLocationId = "test-location-123"
        let originalLastLocation = preferences.getLastSelectedLocation()
        let originalBestLocation = preferences.getBestLocation()

        preferences.saveLastSelectedLocation(with: testLocationId)
        let lastLocation = preferences.getLastSelectedLocation()
        XCTAssertEqual(lastLocation, testLocationId)

        preferences.saveBestLocation(with: testLocationId)
        let bestLocation = preferences.getBestLocation()
        XCTAssertEqual(bestLocation, testLocationId)

        // Cleanup - restore original values
        preferences.saveLastSelectedLocation(with: originalLastLocation)
        preferences.saveBestLocation(with: originalBestLocation)
        preferences.clearSelectedLocations()
    }
}
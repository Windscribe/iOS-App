//
//  LookAndFeelRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class LookAndFeelRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: LookAndFeelRepository!
    var mockPreferences: MockPreferences!
    private var cancellables = Set<AnyCancellable>()

    // Test constants
    private let testCustomPath = "/test/path/image.png"

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPreferences = MockPreferences()

        // Register mock preferences
        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        // Register LookAndFeelRepository
        mockContainer.register(LookAndFeelRepository.self) { r in
            return LookAndFeelRepository(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.container)

        // Set default dark mode in preferences
        mockPreferences.saveDarkMode(darkMode: true)

        // Resolve repository from container
        repository = mockContainer.resolve(LookAndFeelRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockPreferences = nil
        mockContainer = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_shouldLoadDarkModeFromPreferences() {
        // Set dark mode to false in preferences
        mockPreferences.saveDarkMode(darkMode: false)

        // Create new repository instance
        let newRepository = LookAndFeelRepository(preferences: mockPreferences)

        // Wait for async sink to complete
        let expectation = self.expectation(description: "Dark mode loaded")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(newRepository.isDarkMode)
            XCTAssertEqual(newRepository.isDarkModeSubject.value, false)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_initialization_shouldLoadBackgroundEffectsFromPreferences() {
        // Set custom background effects in preferences
        mockPreferences.saveBackgroundEffectConnect(value: Fields.Values.custom)
        mockPreferences.saveBackgroundEffectDisconnect(value: Fields.Values.none)

        // Create new repository instance
        let newRepository = LookAndFeelRepository(preferences: mockPreferences)

        XCTAssertEqual(newRepository.backgroundEffectConnect, .custom)
        XCTAssertEqual(newRepository.backgroundEffectDisconnect, .none)
    }

    func test_initialization_shouldLoadCustomPathsFromPreferences() {
        mockPreferences.saveBackgroundCustomConnectPath(value: testCustomPath)
        mockPreferences.saveBackgroundCustomDisconnectPath(value: testCustomPath)

        let newRepository = LookAndFeelRepository(preferences: mockPreferences)

        XCTAssertEqual(newRepository.backgroundCustomConnectPath, testCustomPath)
        XCTAssertEqual(newRepository.backgroundCustomDisconnectPath, testCustomPath)
    }

    func test_initialization_shouldLoadAspectRatioFromPreferences() {
        mockPreferences.saveAspectRatio(value: Fields.Values.fill)

        let newRepository = LookAndFeelRepository(preferences: mockPreferences)

        XCTAssertEqual(newRepository.backgroundCustomAspectRatio, .fill)
    }

    func test_initialization_withNilPreferences_shouldUseDefaults() {
        // MockPreferences returns nil for optional values by default
        let newRepository = LookAndFeelRepository(preferences: mockPreferences)

        XCTAssertEqual(newRepository.backgroundEffectConnect, .flag) // default
        XCTAssertEqual(newRepository.backgroundEffectDisconnect, .flag) // default
        XCTAssertNil(newRepository.backgroundCustomConnectPath)
        XCTAssertNil(newRepository.backgroundCustomDisconnectPath)
        XCTAssertEqual(newRepository.backgroundCustomAspectRatio, .stretch) // default
    }

    // MARK: - Dark Mode Subject Tests

    func test_isDarkModeSubject_shouldEmitCurrentValue() {
        let expectation = self.expectation(description: "Dark mode emitted")

        repository.isDarkModeSubject
            .sink { isDark in
                XCTAssertTrue(isDark)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_isDarkModeSubject_shouldEmitWhenPreferencesChange() {
        let expectation = self.expectation(description: "Dark mode changed")

        // Skip the first emission (current value) and wait for the new value
        repository.isDarkModeSubject
            .dropFirst()
            .sink { isDark in
                XCTAssertFalse(isDark)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Change dark mode in preferences
        mockPreferences.saveDarkMode(darkMode: false)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_isDarkMode_shouldReflectCurrentValue() {
        XCTAssertTrue(repository.isDarkMode)

        mockPreferences.saveDarkMode(darkMode: false)

        let expectation = self.expectation(description: "Dark mode updated")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.repository.isDarkMode)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - updateBackgroundEffectConnect Tests

    func test_updateBackgroundEffectConnect_shouldUpdateProperty() {
        let newEffect = BackgroundEffectType.bundled(subtype: .palm)

        repository.updateBackgroundEffectConnect(effect: newEffect)

        XCTAssertEqual(repository.backgroundEffectConnect, newEffect)
    }

    func test_updateBackgroundEffectConnect_shouldSaveToPreferences() {
        let newEffect = BackgroundEffectType.custom

        repository.updateBackgroundEffectConnect(effect: newEffect)

        XCTAssertEqual(mockPreferences.getBackgroundEffectConnect(), Fields.Values.custom)
    }

    func test_updateBackgroundEffectConnect_shouldTriggerBackgroundChanged() {
        let expectation = self.expectation(description: "Background changed triggered")

        repository.backgroundChangedTrigger
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        repository.updateBackgroundEffectConnect(effect: .none)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_updateBackgroundEffectConnect_withBundledSubtype_shouldSaveCorrectValue() {
        let newEffect = BackgroundEffectType.bundled(subtype: .city)

        repository.updateBackgroundEffectConnect(effect: newEffect)

        XCTAssertEqual(mockPreferences.getBackgroundEffectConnect(), BackgroundEffectSubtype.city.rawValue)
        XCTAssertEqual(repository.backgroundEffectConnect, newEffect)
    }

    // MARK: - updateBackgroundEffectDisconnect Tests

    func test_updateBackgroundEffectDisconnect_shouldUpdateProperty() {
        let newEffect = BackgroundEffectType.bundled(subtype: .abstract)

        repository.updateBackgroundEffectDisconnect(effect: newEffect)

        XCTAssertEqual(repository.backgroundEffectDisconnect, newEffect)
    }

    func test_updateBackgroundEffectDisconnect_shouldSaveToPreferences() {
        let newEffect = BackgroundEffectType.none

        repository.updateBackgroundEffectDisconnect(effect: newEffect)

        XCTAssertEqual(mockPreferences.getBackgroundEffectDisconnect(), Fields.Values.none)
    }

    func test_updateBackgroundEffectDisconnect_shouldTriggerBackgroundChanged() {
        let expectation = self.expectation(description: "Background changed triggered")

        repository.backgroundChangedTrigger
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        repository.updateBackgroundEffectDisconnect(effect: .custom)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - updateBackgroundCustomConnectPath Tests

    func test_updateBackgroundCustomConnectPath_shouldUpdateProperty() {
        repository.updateBackgroundCustomConnectPath(path: testCustomPath)

        XCTAssertEqual(repository.backgroundCustomConnectPath, testCustomPath)
    }

    func test_updateBackgroundCustomConnectPath_shouldSaveToPreferences() {
        repository.updateBackgroundCustomConnectPath(path: testCustomPath)

        XCTAssertEqual(mockPreferences.getBackgroundCustomConnectPath(), testCustomPath)
    }

    func test_updateBackgroundCustomConnectPath_shouldTriggerBackgroundChanged() {
        let expectation = self.expectation(description: "Background changed triggered")

        repository.backgroundChangedTrigger
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        repository.updateBackgroundCustomConnectPath(path: testCustomPath)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_updateBackgroundCustomConnectPath_withEmptyString_shouldUpdate() {
        repository.updateBackgroundCustomConnectPath(path: "")

        XCTAssertEqual(repository.backgroundCustomConnectPath, "")
        XCTAssertEqual(mockPreferences.getBackgroundCustomConnectPath(), "")
    }

    // MARK: - updateBackgroundCustomDisconnectPath Tests

    func test_updateBackgroundCustomDisconnectPath_shouldUpdateProperty() {
        repository.updateBackgroundCustomDisconnectPath(path: testCustomPath)

        XCTAssertEqual(repository.backgroundCustomDisconnectPath, testCustomPath)
    }

    func test_updateBackgroundCustomDisconnectPath_shouldSaveToPreferences() {
        repository.updateBackgroundCustomDisconnectPath(path: testCustomPath)

        XCTAssertEqual(mockPreferences.getBackgroundCustomDisconnectPath(), testCustomPath)
    }

    func test_updateBackgroundCustomDisconnectPath_shouldTriggerBackgroundChanged() {
        let expectation = self.expectation(description: "Background changed triggered")

        repository.backgroundChangedTrigger
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        repository.updateBackgroundCustomDisconnectPath(path: testCustomPath)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - updateBackgroundCustomAspectRatio Tests

    func test_updateBackgroundCustomAspectRatio_shouldUpdateProperty() {
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .fill)

        XCTAssertEqual(repository.backgroundCustomAspectRatio, .fill)
    }

    func test_updateBackgroundCustomAspectRatio_shouldSaveToPreferences() {
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .tile)

        XCTAssertEqual(mockPreferences.getAspectRatio(), Fields.Values.tile)
    }

    func test_updateBackgroundCustomAspectRatio_shouldTriggerBackgroundChanged() {
        let expectation = self.expectation(description: "Background changed triggered")

        repository.backgroundChangedTrigger
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        repository.updateBackgroundCustomAspectRatio(aspectRatio: .fill)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_updateBackgroundCustomAspectRatio_allValues_shouldWorkCorrectly() {
        // Test stretch
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .stretch)
        XCTAssertEqual(repository.backgroundCustomAspectRatio, .stretch)
        XCTAssertEqual(mockPreferences.getAspectRatio(), Fields.Values.stretch)

        // Test fill
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .fill)
        XCTAssertEqual(repository.backgroundCustomAspectRatio, .fill)
        XCTAssertEqual(mockPreferences.getAspectRatio(), Fields.Values.fill)

        // Test tile
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .tile)
        XCTAssertEqual(repository.backgroundCustomAspectRatio, .tile)
        XCTAssertEqual(mockPreferences.getAspectRatio(), Fields.Values.tile)
    }

    // MARK: - backgroundChangedTrigger Tests

    func test_backgroundChangedTrigger_shouldEmitForEachUpdate() {
        var triggerCount = 0
        let expectation = self.expectation(description: "Background changed multiple times")

        repository.backgroundChangedTrigger
            .sink { _ in
                triggerCount += 1
                if triggerCount == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        repository.updateBackgroundEffectConnect(effect: .none)
        repository.updateBackgroundEffectDisconnect(effect: .custom)
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .fill)

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(triggerCount, 3)
    }

    func test_backgroundChangedTrigger_shouldNotEmitForDarkModeChange() {
        var triggerCount = 0

        repository.backgroundChangedTrigger
            .sink { _ in
                triggerCount += 1
            }
            .store(in: &cancellables)

        // Change dark mode - should NOT trigger background changed
        mockPreferences.saveDarkMode(darkMode: false)

        // Wait a bit to ensure no emission
        let expectation = self.expectation(description: "Wait for potential emission")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(triggerCount, 0)
    }

    // MARK: - Integration Tests

    func test_multipleUpdates_shouldMaintainConsistency() {
        // Perform multiple updates
        repository.updateBackgroundEffectConnect(effect: .custom)
        repository.updateBackgroundEffectDisconnect(effect: .none)
        repository.updateBackgroundCustomConnectPath(path: "/path1")
        repository.updateBackgroundCustomDisconnectPath(path: "/path2")
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .tile)

        // Verify all values are correct
        XCTAssertEqual(repository.backgroundEffectConnect, .custom)
        XCTAssertEqual(repository.backgroundEffectDisconnect, .none)
        XCTAssertEqual(repository.backgroundCustomConnectPath, "/path1")
        XCTAssertEqual(repository.backgroundCustomDisconnectPath, "/path2")
        XCTAssertEqual(repository.backgroundCustomAspectRatio, .tile)

        // Verify preferences are updated
        XCTAssertEqual(mockPreferences.getBackgroundEffectConnect(), Fields.Values.custom)
        XCTAssertEqual(mockPreferences.getBackgroundEffectDisconnect(), Fields.Values.none)
        XCTAssertEqual(mockPreferences.getBackgroundCustomConnectPath(), "/path1")
        XCTAssertEqual(mockPreferences.getBackgroundCustomDisconnectPath(), "/path2")
        XCTAssertEqual(mockPreferences.getAspectRatio(), Fields.Values.tile)
    }

    func test_persistenceBetweenInstances_shouldMaintainState() {
        // Update values in first instance
        repository.updateBackgroundEffectConnect(effect: .bundled(subtype: .windscribe))
        repository.updateBackgroundCustomAspectRatio(aspectRatio: .fill)

        // Create new instance with same preferences
        let newRepository = LookAndFeelRepository(preferences: mockPreferences)

        // Verify values are loaded from preferences
        XCTAssertEqual(newRepository.backgroundEffectConnect, .bundled(subtype: .windscribe))
        XCTAssertEqual(newRepository.backgroundCustomAspectRatio, .fill)
    }

    func test_allBackgroundEffectTypes_shouldWorkCorrectly() {
        // Test .none
        repository.updateBackgroundEffectConnect(effect: .none)
        XCTAssertEqual(repository.backgroundEffectConnect, .none)

        // Test .flag
        repository.updateBackgroundEffectConnect(effect: .flag)
        XCTAssertEqual(repository.backgroundEffectConnect, .flag)

        // Test .custom
        repository.updateBackgroundEffectConnect(effect: .custom)
        XCTAssertEqual(repository.backgroundEffectConnect, .custom)

        // Test all bundled subtypes
        for subtype in BackgroundEffectSubtype.allCases {
            repository.updateBackgroundEffectConnect(effect: .bundled(subtype: subtype))
            XCTAssertEqual(repository.backgroundEffectConnect, .bundled(subtype: subtype))
        }
    }

    // MARK: - Edge Cases

    func test_rapidUpdates_shouldHandleGracefully() {
        var triggerCount = 0

        repository.backgroundChangedTrigger
            .sink { _ in
                triggerCount += 1
            }
            .store(in: &cancellables)

        // Perform rapid updates
        for i in 0..<10 {
            let path = "/path\(i)"
            repository.updateBackgroundCustomConnectPath(path: path)
        }

        // Verify final state
        XCTAssertEqual(repository.backgroundCustomConnectPath, "/path9")
        XCTAssertEqual(triggerCount, 10)
    }

    func test_sameValueUpdate_shouldStillTriggerAndSave() {
        var triggerCount = 0

        repository.backgroundChangedTrigger
            .sink { _ in
                triggerCount += 1
            }
            .store(in: &cancellables)

        // Update to same value twice
        repository.updateBackgroundEffectConnect(effect: .flag)
        repository.updateBackgroundEffectConnect(effect: .flag)

        // Should still trigger and save both times
        XCTAssertEqual(triggerCount, 2)
        XCTAssertEqual(repository.backgroundEffectConnect, .flag)
    }
}

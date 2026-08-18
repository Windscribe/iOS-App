//
//  AntiCensorshipRepositoryTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-08-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("AntiCensorshipRepository protocol tweaks modes")
struct AntiCensorshipRepositoryTests {

    private func makeParam(id: String, title: String) -> UnblockWgParams {
        UnblockWgParams(id: id, title: title, countries: [],
                        jc: nil, jMin: nil, jMax: nil,
                        s1: nil, s2: nil, s3: nil, s4: nil,
                        h1: nil, h2: nil, h3: nil, h4: nil,
                        i1: nil, i2: nil, i3: nil, i4: nil, i5: nil)
    }

    private func makeStores() -> (MockPreferences, MockLocalDatabase) {
        let preferences = MockPreferences()
        let localDatabase = MockLocalDatabase()
        localDatabase.mockUnblockWgParams = [
            makeParam(id: "G", title: "G - QUIC"),
            makeParam(id: "J", title: "J - Iran Junk Packets")
        ]
        return (preferences, localDatabase)
    }

    private func makeRepository(preferences: MockPreferences,
                                localDatabase: MockLocalDatabase) -> AntiCensorshipRepositoryImpl {
        AntiCensorshipRepositoryImpl(apiManager: MockAPIManager(),
                                     logger: MockLogger(),
                                     localDatabase: localDatabase,
                                     preferences: preferences)
    }

    @Test("Never-configured legacy state migrates to Auto")
    func legacyAutomaticMigration() {
        let (preferences, localDatabase) = makeStores()
        preferences.mockCircumventCensorshipEnabled = true

        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        #expect(repository.protocolTweaksModeSubject.value == .auto)
        #expect(repository.useProtocolTweaksSubject.value == false)
        #expect(preferences.mockProtocolTweaksMode == ProtocolTweaksMode.auto.rawValue)
    }

    @Test("Manually enabled legacy state migrates to Enabled")
    func legacyEnabledMigration() {
        let (preferences, localDatabase) = makeStores()
        preferences.mockAntiCensorshipManuallyConfigured = true
        preferences.mockCircumventCensorshipEnabled = true
        preferences.mockUnblockWgParams = makeParam(id: "J", title: "J - Iran Junk Packets")

        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        #expect(repository.protocolTweaksModeSubject.value == .enabled)
        #expect(repository.useProtocolTweaksSubject.value == true)
        #expect(repository.selectedWgParamSubject.value?.id == "J")
        #expect(preferences.mockProtocolTweaksMode == ProtocolTweaksMode.enabled.rawValue)
    }

    @Test("Manually disabled legacy state migrates to Disabled")
    func legacyDisabledMigration() {
        let (preferences, localDatabase) = makeStores()
        preferences.mockAntiCensorshipManuallyConfigured = true
        preferences.mockCircumventCensorshipEnabled = false

        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        #expect(repository.protocolTweaksModeSubject.value == .disabled)
        #expect(repository.useProtocolTweaksSubject.value == false)
        #expect(repository.selectedWgParamSubject.value == nil)
        #expect(preferences.mockProtocolTweaksMode == ProtocolTweaksMode.disabled.rawValue)
    }

    @Test("Auto follows valid, changed, empty, and unknown session recommendations")
    func automaticSessionRecommendations() {
        let (preferences, localDatabase) = makeStores()
        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        repository.setSessionWgParameter(withId: "G")
        #expect(repository.useProtocolTweaksSubject.value == true)
        #expect(repository.selectedWgParamSubject.value?.id == "G")

        repository.setSessionWgParameter(withId: "J")
        #expect(repository.useProtocolTweaksSubject.value == true)
        #expect(repository.selectedWgParamSubject.value?.id == "J")

        repository.setSessionWgParameter(withId: "")
        #expect(repository.useProtocolTweaksSubject.value == false)
        #expect(repository.selectedWgParamSubject.value == nil)

        repository.setSessionWgParameter(withId: "unknown")
        #expect(repository.useProtocolTweaksSubject.value == false)
        #expect(repository.selectedWgParamSubject.value == nil)
    }

    @Test("Enabled selection survives repository recreation and session refresh")
    func enabledSelectionPersists() {
        let (preferences, localDatabase) = makeStores()
        let firstLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        firstLaunch.setProtocolTweaksMode(.enabled)
        firstLaunch.setWgParameter(withId: "J")

        let secondLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        secondLaunch.setSessionWgParameter(withId: "G")

        #expect(secondLaunch.protocolTweaksModeSubject.value == .enabled)
        #expect(secondLaunch.useProtocolTweaksSubject.value == true)
        #expect(secondLaunch.selectedWgParamSubject.value?.id == "J")
        #expect(preferences.getUnblockWgParams()?.id == "J")
    }

    @Test("Disabled mode survives repository recreation and session refresh")
    func disabledModePersists() {
        let (preferences, localDatabase) = makeStores()
        let firstLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        firstLaunch.setProtocolTweaksMode(.disabled)

        let secondLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        secondLaunch.setSessionWgParameter(withId: "G")

        #expect(secondLaunch.protocolTweaksModeSubject.value == .disabled)
        #expect(secondLaunch.useProtocolTweaksSubject.value == false)
        #expect(secondLaunch.selectedWgParamSubject.value == nil)
    }

    @Test("Returning to Auto persists and restores session ownership")
    func returningToAuto() {
        let (preferences, localDatabase) = makeStores()
        let firstLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        firstLaunch.setProtocolTweaksMode(.enabled)
        firstLaunch.setWgParameter(withId: "J")
        firstLaunch.setProtocolTweaksMode(.auto)

        let secondLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        secondLaunch.setSessionWgParameter(withId: "G")

        #expect(secondLaunch.protocolTweaksModeSubject.value == .auto)
        #expect(secondLaunch.useProtocolTweaksSubject.value == true)
        #expect(secondLaunch.selectedWgParamSubject.value?.id == "G")
        #expect(preferences.mockAntiCensorshipManuallyConfigured == false)
    }
}

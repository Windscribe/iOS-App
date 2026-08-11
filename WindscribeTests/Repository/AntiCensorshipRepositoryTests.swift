//
//  AntiCensorshipRepositoryTests.swift
//  WindscribeTests
//
//  Created by Dev Scribe on 2026-08-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("AntiCensorshipRepository manual override persistence")
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

    @Test("Session preset does not overwrite a manually selected preset")
    func manualPresetSurvivesSessionPreset() {
        let (preferences, localDatabase) = makeStores()
        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        repository.setUseProtocolTweaks(true)
        repository.setWgParameter(withId: "J")

        repository.setSessionWgParameter(withId: "G")

        #expect(repository.selectedWgParamSubject.value?.id == "J")
        #expect(preferences.getUnblockWgParams()?.id == "J")
        #expect(repository.useProtocolTweaksSubject.value == true)
    }

    @Test("Session preset does not re-enable manually disabled Anti-Censorship")
    func manualDisableSurvivesSessionPreset() {
        let (preferences, localDatabase) = makeStores()
        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        repository.setUseProtocolTweaks(true)
        repository.setUseProtocolTweaks(false)

        repository.setSessionWgParameter(withId: "G")

        #expect(repository.useProtocolTweaksSubject.value == false)
        #expect(repository.selectedWgParamSubject.value == nil)
        #expect(preferences.isCircumventCensorshipEnabled() == false)
    }

    @Test("Manual selection survives repository recreation plus session bootstrap")
    func manualOwnershipSurvivesRelaunch() {
        let (preferences, localDatabase) = makeStores()
        let firstLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        firstLaunch.setUseProtocolTweaks(true)
        firstLaunch.setWgParameter(withId: "J")

        let secondLaunch = makeRepository(preferences: preferences, localDatabase: localDatabase)
        secondLaunch.setSessionWgParameter(withId: "G")

        #expect(secondLaunch.selectedWgParamSubject.value?.id == "J")
        #expect(secondLaunch.useProtocolTweaksSubject.value == true)
    }

    @Test("Never-configured user still gets automatic session preset")
    func automaticSessionSelectionStillApplies() {
        let (preferences, localDatabase) = makeStores()
        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)

        repository.setSessionWgParameter(withId: "G")

        #expect(repository.useProtocolTweaksSubject.value == true)
        #expect(repository.selectedWgParamSubject.value?.id == "G")
        #expect(preferences.getUnblockWgParams()?.id == "G")
    }

    @Test("Empty session preset leaves manual state alone")
    func emptySessionPresetLeavesManualStateAlone() {
        let (preferences, localDatabase) = makeStores()
        let repository = makeRepository(preferences: preferences, localDatabase: localDatabase)
        repository.setUseProtocolTweaks(true)
        repository.setWgParameter(withId: "J")

        repository.setSessionWgParameter(withId: "")

        #expect(repository.selectedWgParamSubject.value?.id == "J")
        #expect(repository.useProtocolTweaksSubject.value == true)
    }
}

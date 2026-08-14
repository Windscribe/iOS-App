//
//  GeneralTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-05-19.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Combine
import Testing
import Foundation
import UniformTypeIdentifiers
@testable import Windscribe

@Suite("GeneralViewModel")
@MainActor
struct GeneralViewModelTests {

    // MARK: - Init seeding

    @Test("Initialises preference-backed state from PreferencesReading")
    func initialPreferenceState() {
        let prefs = StubPreferencesReading(
            locationOrder: "geography",
            isHapticFeedbackEnabled: false,
            isLocationLoadEnabled: true
        )
        let vm = makeViewModel(preferencesReading: prefs)
        let entries = vm.entries

        #expect(entries.contains { entry in
            if case let .locationOrder(currentOption, _) = entry { return currentOption == "geography" }
            return false
        })
        #expect(entries.contains { entry in
            if case let .hapticFeedback(isSelected) = entry { return isSelected == false }
            return false
        })
        #expect(entries.contains { entry in
            if case let .locationLoad(isSelected) = entry { return isSelected == true }
            return false
        })
    }

    @Test("Initialises language from LanguageStoring.activeLanguage")
    func initialLanguage() {
        let lang = MockLanguageStoring(active: .spanish)
        let vm = makeViewModel(languageStoring: lang)
        #expect(vm.entries.contains { entry in
            if case let .language(currentOption, _) = entry {
                return currentOption == Languages.spanish.name
            }
            return false
        })
    }

    @Test("Entries appear in the documented order")
    func entriesOrder() {
        let vm = makeViewModel()
        let kinds = vm.entries.map(entryKind)
        #expect(kinds == [
            .locationOrder, .language, .locationLoad,
            .hapticFeedback, .notification, .version
        ])
    }

    // MARK: - Writes

    @Test("Toggling hapticFeedback writes through")
    func toggleHapticPersists() {
        let writer = MockPreferencesWriting()
        let vm = makeViewModel(preferencesWriting: writer)

        vm.entrySelected(.hapticFeedback(isSelected: false),
                         action: .toggle(isSelected: true, parentId: 0))

        #expect(writer.savedHaptic == true)
    }

    @Test("Toggling locationLoad writes through")
    func toggleLocationLoadPersists() {
        let writer = MockPreferencesWriting()
        let vm = makeViewModel(preferencesWriting: writer)

        vm.entrySelected(.locationLoad(isSelected: false),
                         action: .toggle(isSelected: true, parentId: 0))

        #expect(writer.savedShowServerNetLoad == true)
    }

    @Test("Selecting a locationOrder option writes through")
    func locationOrderPersists() {
        let writer = MockPreferencesWriting()
        let vm = makeViewModel(preferencesWriting: writer)

        vm.entrySelected(.locationOrder(currentOption: "geography", options: []),
                         action: .multiple(newOption: "alphabetical", parentId: 0))

        #expect(writer.savedOrderLocationsBy == "alphabetical")
    }

    @Test("Selecting a language updates the active language")
    func languageSelectionPersists() {
        let lang = MockLanguageStoring(active: .english)
        let vm = makeViewModel(languageStoring: lang)

        vm.entrySelected(.language(currentOption: Languages.english.name, options: []),
                         action: .multiple(newOption: Languages.spanish.name, parentId: 0))

        #expect(lang.setLanguageCalls == [.spanish])
    }

    @Test("Toggle actions fire haptic feedback")
    func togglesFireHaptic() {
        let haptic = MockHapticFeedbacking()
        let vm = makeViewModel(hapticFeedback: haptic)

        vm.entrySelected(.hapticFeedback(isSelected: false),
                         action: .toggle(isSelected: true, parentId: 0))

        #expect(haptic.checkedActionCount == 1)
    }

    @Test("Notification entry routes to PushNotificationManaging.handleSettingsTap")
    func notificationEntryRoutes() async throws {
        let push = MockPushNotificationManaging()
        let vm = makeViewModel(pushNotifications: push)

        vm.entrySelected(.notification(title: "open"), action: .toggle(isSelected: false, parentId: 0))

        // `entrySelected` launches an unstructured Task; poll briefly for the call.
        try await waitFor({ push.handleSettingsTapCount == 1 })
    }

    @Test("Version entry is a no-op (no writes, no haptic side-effects)")
    func versionEntryNoOp() {
        let writer = MockPreferencesWriting()
        let push = MockPushNotificationManaging()
        let vm = makeViewModel(preferencesWriting: writer, pushNotifications: push)

        vm.entrySelected(.version(message: "v1"), action: .toggle(isSelected: false, parentId: 0))

        #expect(writer.savedHaptic == nil)
        #expect(writer.savedShowServerNetLoad == nil)
        #expect(writer.savedOrderLocationsBy == nil)
        #expect(push.handleSettingsTapCount == 0)
    }

    // MARK: - Observers

    @Test("observeLocationLoadEnabled reflects stream emissions")
    func observeLocationLoad_streamUpdates() async throws {
        let prefs = StubPreferencesReading(isLocationLoadEnabled: false)
        let vm = makeViewModel(preferencesReading: prefs)

        let task = Task { await vm.observeLocationLoadEnabled() }
        defer { task.cancel() }

        // Give the observer task a chance to subscribe before emitting.
        await Task.yield()

        prefs.sendLocationLoad(true)
        try await waitFor({ locationLoadFlag(in: vm.entries) == true })
        prefs.sendLocationLoad(false)
        try await waitFor({ locationLoadFlag(in: vm.entries) == false })
    }

    // MARK: - Helpers

    private func makeViewModel(
        hapticFeedback: any HapticFeedbacking = MockHapticFeedbacking(),
        languageStoring: any LanguageStoring = MockLanguageStoring(),
        preferencesReading: any PreferencesReading = StubPreferencesReading(),
        preferencesWriting: any PreferencesWriting = MockPreferencesWriting(),
        pushNotifications: any PushNotificationManaging = MockPushNotificationManaging()
    ) -> GeneralViewModel {
        GeneralViewModel(
            hapticFeedback: hapticFeedback,
            languageStoring: languageStoring,
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting,
            pushNotifications: pushNotifications
        )
    }

    private func waitFor(
        _ condition: @MainActor () -> Bool,
        timeout: Duration = .milliseconds(200)
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while !condition() && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(condition())
    }

    /// Coarse classification used by `entriesOrder` so the assertion isn't
    /// coupled to the exact strings/options the VM threads into each case.
    private enum EntryKind: Equatable {
        case locationOrder, language, locationLoad, hapticFeedback, notification, version
    }

    private func entryKind(_ entry: GeneralMenuEntryType) -> EntryKind {
        switch entry {
        case .locationOrder: return .locationOrder
        case .language: return .language
        case .locationLoad: return .locationLoad
        case .hapticFeedback: return .hapticFeedback
        case .notification: return .notification
        case .version: return .version
        }
    }

    private func locationLoadFlag(in entries: [GeneralMenuEntryType]) -> Bool? {
        for entry in entries {
            if case let .locationLoad(isSelected) = entry { return isSelected }
        }
        return nil
    }
}

@Suite("Main screen localization refresh")
@MainActor
struct MainScreenLocalizationRefreshTests {
    @Test("Language changes refresh an unknown network label but preserve a known SSID")
    func refreshesUnknownNetworkOnly() async throws {
        let languageManager = StubLanguageManager()
        let viewModel = WifiInfoViewModel(
            preferences: MockPreferences(),
            wifiManager: MockWifiManager(),
            languageManager: languageManager
        )
        let view = WifiInfoView()
        view.viewModel = viewModel

        view.nameLabel.text = "stale unknown network"
        languageManager.setLanguage(language: .spanish)
        try await waitFor {
            view.nameLabel.text == TextsAsset.NetworkSecurity.unknownNetwork
        }

        view.updateWifiName(name: "Home WiFi")
        languageManager.setLanguage(language: .french)
        await drainMainQueue()

        #expect(view.nameLabel.text == "Home WiFi")
    }

    @Test("Language changes localize the disconnected pill before VPN state loads")
    func refreshesDisconnectedStatusWithoutLoadedState() async throws {
        let viewModel = StubConnectionStateInfoViewModel()
        let view = ConnectionStateInfoView(wifiManager: MockWifiManager())
        view.viewModel = viewModel
        await drainMainQueue()

        view.pillLabel.text = "stale status"
        viewModel.activeLanguageSubject.send(.spanish)

        try await waitFor { view.pillLabel.text == TextsAsset.Status.off }
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    private func waitFor(
        _ condition: @MainActor () -> Bool,
        timeout: Duration = .milliseconds(200)
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while !condition() && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(condition())
    }
}

private final class StubLanguageManager: LanguageManager, @unchecked Sendable {
    let activelanguage = CurrentValueSubject<Languages, Never>(.english)

    func setAppLanguage() {}

    func setLanguage(language: Languages) {
        activelanguage.send(language)
    }

    func getCurrentLanguage() -> Languages {
        activelanguage.value
    }
}

private final class StubConnectionStateInfoViewModel: ConnectionStateInfoViewModelType {
    let statusSubject = CurrentValueSubject<ConnectionState?, Never>(nil)
    let hasNetwork = CurrentValueSubject<Bool, Never>(true)
    let isCircumventCensorshipEnabled = CurrentValueSubject<Bool, Never>(false)
    let refreshProtocolSubject = CurrentValueSubject<ProtocolPort?, Never>(nil)
    let activeLanguageSubject = CurrentValueSubject<Languages, Never>(.english)
    let isCustomConfigSelected = false
    let isAntiCensorshipEnabled = false
    let isConnecting = false
    let isConnected = false
}

// MARK: - Mocks

final class MockHapticFeedbacking: HapticFeedbacking, @unchecked Sendable {
    var hapticFeedbackEnabled: Bool = false

    private(set) var checkedActionCount = 0
    private(set) var runLevels: [HapticFeedbackLevel] = []

    func checkSettingsAction(action: MenuEntryActionResponseType) {
        checkedActionCount += 1
    }

    func run(level: HapticFeedbackLevel) {
        runLevels.append(level)
    }
}

final class MockLanguageStoring: LanguageStoring, @unchecked Sendable {
    private(set) var setLanguageCalls: [Languages] = []
    var activeLanguage: Languages?
    private var continuation: AsyncStream<Languages>.Continuation?

    init(active: Languages? = .english) {
        self.activeLanguage = active
    }

    var languageUpdates: AsyncStream<Languages> {
        AsyncStream { continuation in
            self.continuation = continuation
            if let active = self.activeLanguage {
                continuation.yield(active)
            }
        }
    }

    func setActiveLanguage(language: Languages) {
        activeLanguage = language
        setLanguageCalls.append(language)
        continuation?.yield(language)
    }
}

@Suite("Menu entry identity")
struct MenuEntryIdentityTests {
    @Test("Secondary menu entries hash by the same fields used for equality")
    func secondaryEntryHashMatchesIdEquality() {
        let first = MenuSecondaryEntryItem(entry: StubMenuEntryItem(id: 7,
                                                                    title: "First",
                                                                    icon: "first",
                                                                    action: .none(title: "First", parentId: 7)))
        let second = MenuSecondaryEntryItem(entry: StubMenuEntryItem(id: 7,
                                                                     title: "Second",
                                                                     icon: "second",
                                                                     action: .toggle(isSelected: true, parentId: 7)))

        #expect(first == second)
        #expect(Set([first, second]).count == 1)

        var entries: [MenuSecondaryEntryItem: String] = [:]
        entries[first] = "first"
        entries[second] = "second"

        #expect(entries.count == 1)
        #expect(entries[first] == "second")
    }

    @Test("Document export identity includes file data")
    func documentFormatInfoEqualityIncludesFileData() {
        let first = DocumentFormatInfo(fileData: Data("first".utf8),
                                       type: .plainText,
                                       tempFileName: "debug-log.txt")
        let second = DocumentFormatInfo(fileData: Data("other".utf8),
                                        type: .plainText,
                                        tempFileName: "debug-log.txt")

        #expect(first != second)
    }
}

private struct StubMenuEntryItem: MenuEntryItemType {
    let id: Int
    let title: String
    let icon: String
    let action: MenuEntryActionType?
}

final class StubPreferencesReading: PreferencesReading, @unchecked Sendable {
    var killSwitchEnabled = false
    var allowLAN = false
    var selectedProtocol: String?
    var selectedPort: String?
    var locationOrder: String?
    var isHapticFeedbackEnabled: Bool
    var isLocationLoadEnabled: Bool
    var soundEffectConnect: String?
    var soundEffectDisconnect: String?
    var customSoundPathConnect: String?
    var customSoundPathDisconnect: String?
    var customAppIcon: String?
    var connectionMode: String?
    var connectedDNS: String?
    var customDNSValue = ""
    var egressProtocol: String?
    var ingressProtocol: String?
    var autoSecureNewNetworks = false
    var ssoProvider: String?
    var tlsServerName: String?
    var advanceParams: String?

    private var locationLoadContinuation: AsyncStream<Bool>.Continuation?
    private var hapticContinuation: AsyncStream<Bool>.Continuation?
    private var orderContinuation: AsyncStream<String>.Continuation?

    init(locationOrder: String? = nil,
         isHapticFeedbackEnabled: Bool = true,
         isLocationLoadEnabled: Bool = false) {
        self.locationOrder = locationOrder
        self.isHapticFeedbackEnabled = isHapticFeedbackEnabled
        self.isLocationLoadEnabled = isLocationLoadEnabled
    }

    var locationLoadUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            self.locationLoadContinuation = continuation
            continuation.yield(self.isLocationLoadEnabled)
        }
    }

    var hapticFeedbackUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            self.hapticContinuation = continuation
            continuation.yield(self.isHapticFeedbackEnabled)
        }
    }

    var locationOrderUpdates: AsyncStream<String> {
        AsyncStream { continuation in
            self.orderContinuation = continuation
            continuation.yield(self.locationOrder ?? DefaultValues.orderLocationsBy)
        }
    }

    var selectedProtocolUpdates: AsyncStream<String?> { stream(value: selectedProtocol) }
    var selectedPortUpdates: AsyncStream<String?> { stream(value: selectedPort) }
    var killSwitchUpdates: AsyncStream<Bool> { stream(value: killSwitchEnabled) }
    var allowLANUpdates: AsyncStream<Bool> { stream(value: allowLAN) }
    var connectionModeUpdates: AsyncStream<String?> { stream(value: connectionMode) }
    var connectedDNSUpdates: AsyncStream<String?> { stream(value: connectedDNS) }
    var egressProtocolUpdates: AsyncStream<String?> { stream(value: egressProtocol) }
    var ingressProtocolUpdates: AsyncStream<String?> { stream(value: ingressProtocol) }
    var autoSecureUpdates: AsyncStream<Bool> { stream(value: autoSecureNewNetworks) }

    private func stream<Value>(value: Value) -> AsyncStream<Value> {
        AsyncStream { continuation in
            continuation.yield(value)
        }
    }

    func sendLocationLoad(_ value: Bool) {
        isLocationLoadEnabled = value
        locationLoadContinuation?.yield(value)
    }

    func sendHaptic(_ value: Bool) {
        isHapticFeedbackEnabled = value
        hapticContinuation?.yield(value)
    }

    func sendOrder(_ value: String) {
        locationOrder = value
        orderContinuation?.yield(value)
    }

    func getCustomAppIcon() -> String? {
        customAppIcon
    }
}

final class MockPreferencesWriting: PreferencesWriting, @unchecked Sendable {
    private(set) var savedShowServerNetLoad: Bool?
    private(set) var savedHaptic: Bool?
    private(set) var savedOrderLocationsBy: String?
    private(set) var savedSSOProvider: String?
    private(set) var savedCustomAppIcon: String?
    private(set) var savedConnectionMode: String?
    private(set) var savedSelectedProtocol: String?
    private(set) var savedSelectedPort: String?
    private(set) var savedKillSwitch: Bool?
    private(set) var savedAllowLAN: Bool?
    private(set) var savedConnectedDNS: String?
    private(set) var savedCustomDNSValue: DNSValue?
    private(set) var savedEgressProtocolPreference: String?
    private(set) var savedIngressProtocolPreference: String?
    private(set) var savedAutoSecureNewNetworks: Bool?
    private(set) var savedAdvanceParams: String?
    private(set) var savedTlsServerName: String?

    func saveShowServerNetLoad(show: Bool) { savedShowServerNetLoad = show }
    func saveHapticFeedback(haptic: Bool) { savedHaptic = haptic }
    func saveOrderLocationsBy(order: String) { savedOrderLocationsBy = order }
    func saveSSOProvider(provider: String) { savedSSOProvider = provider }
    func saveCustomAppIcon(value: String) { savedCustomAppIcon = value }
    func saveConnectionMode(mode: String) { savedConnectionMode = mode }
    func saveSelectedProtocol(selectedProtocol: String) { savedSelectedProtocol = selectedProtocol }
    func saveSelectedPort(port: String) { savedSelectedPort = port }
    func saveKillSwitch(killSwitch: Bool) { savedKillSwitch = killSwitch }
    func saveAllowLAN(mode: Bool) { savedAllowLAN = mode }
    func saveConnectedDNS(mode: String) { savedConnectedDNS = mode }
    func saveCustomDNSValue(value: DNSValue) { savedCustomDNSValue = value }
    func saveEgressProtocolPreference(value: String) { savedEgressProtocolPreference = value }
    func saveIngressProtocolPreference(value: String) { savedIngressProtocolPreference = value }
    func saveAutoSecureNewNetworks(autoSecure: Bool) { savedAutoSecureNewNetworks = autoSecure }
    func saveAdvanceParams(params: String) { savedAdvanceParams = params }
    func saveTlsServerName(value: String) { savedTlsServerName = value }
}

final class MockPushNotificationManaging: PushNotificationManaging, @unchecked Sendable {
    private(set) var askPermissionCount = 0
    private(set) var handleSettingsTapCount = 0

    func askForPushNotificationPermission() {
        askPermissionCount += 1
    }

    @MainActor
    func handleSettingsTap() async {
        handleSettingsTapCount += 1
    }
}

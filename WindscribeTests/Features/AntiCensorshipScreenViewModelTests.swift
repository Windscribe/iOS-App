//
//  AntiCensorshipScreenViewModelTests.swift
//  WindscribeTests
//

import Foundation
import Testing

@testable import Windscribe

@Suite("Anti-censorship screen view model")
@MainActor
struct AntiCensorshipScreenViewModelTests {

    @Test("TLS server name entry is initialized from preferences")
    func tlsServerNameInitialValue() {
        let reader = StubPreferencesReading()
        reader.tlsServerName = "front.example.com"

        let viewModel = makeViewModel(preferencesReading: reader)

        #expect(tlsServerName(in: viewModel.entries) == "front.example.com")
    }

    @Test("TLS server name field action updates the entry and preferences")
    func tlsServerNameFieldActionPersists() {
        let writer = MockPreferencesWriting()
        let viewModel = makeViewModel(preferencesWriting: writer)

        viewModel.entrySelected(
            .tlsServerName(value: "", placeholder: ""),
            action: .field(value: "front.example.com", parentId: 0)
        )

        #expect(writer.savedTlsServerName == "front.example.com")
        #expect(tlsServerName(in: viewModel.entries) == "front.example.com")
    }

    @Test("Protocol Tweaks is an Auto, Enabled, Disabled dropdown")
    func protocolTweaksDropdown() {
        let viewModel = makeViewModel()
        let entry = protocolTweaksEntry(in: viewModel.entries)

        #expect(entry?.title == TextsAsset.Connection.protocolTweaks)
        guard let action = entry?.action else {
            Issue.record("Missing Protocol Tweaks action")
            return
        }
        if case let .multiple(currentOption, options, parentId) = action {
            #expect(currentOption == TextsAsset.General.auto)
            #expect(options.map(\.fieldKey) == ProtocolTweaksMode.allCases.map(\.rawValue))
            #expect(parentId == entry?.id)
        } else {
            Issue.record("Expected Protocol Tweaks dropdown")
        }
    }

    @Test("Configuration is visible only in Enabled mode")
    func configurationVisibility() {
        let manager = StubAntiCensorshipManaging()
        let viewModel = makeViewModel(antiCensorshipManaging: manager)
        guard let entry = protocolTweaksEntry(in: viewModel.entries) else {
            Issue.record("Missing Protocol Tweaks entry")
            return
        }

        #expect(hasConfiguration(entry) == false)

        viewModel.entrySelected(entry, action: .multiple(newOption: ProtocolTweaksMode.enabled.rawValue,
                                                         parentId: entry.id))
        guard let enabledEntry = protocolTweaksEntry(in: viewModel.entries) else {
            Issue.record("Missing enabled Protocol Tweaks entry")
            return
        }
        #expect(manager.protocolTweaksMode == .enabled)
        #expect(hasConfiguration(enabledEntry) == true)

        viewModel.entrySelected(enabledEntry, action: .multiple(newOption: ProtocolTweaksMode.disabled.rawValue,
                                                                parentId: enabledEntry.id))
        guard let disabledEntry = protocolTweaksEntry(in: viewModel.entries) else {
            Issue.record("Missing disabled Protocol Tweaks entry")
            return
        }
        #expect(manager.protocolTweaksMode == .disabled)
        #expect(hasConfiguration(disabledEntry) == false)
    }

    private func makeViewModel(
        antiCensorshipManaging: any AntiCensorshipManaging = StubAntiCensorshipManaging(),
        preferencesReading: any PreferencesReading = StubPreferencesReading(),
        preferencesWriting: any PreferencesWriting = MockPreferencesWriting()
    ) -> AntiCensorshipScreenViewModel {
        AntiCensorshipScreenViewModel(
            antiCensorshipManaging: antiCensorshipManaging,
            hapticFeedback: MockHapticFeedbacking(),
            logger: StubLogStoring(),
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting
        )
    }

    private func tlsServerName(in entries: [AntiCensorshipOptionsEntryType]) -> String? {
        for entry in entries {
            if case let .tlsServerName(value, _) = entry {
                return value
            }
        }
        return nil
    }

    private func protocolTweaksEntry(in entries: [AntiCensorshipOptionsEntryType]) -> AntiCensorshipOptionsEntryType? {
        entries.first {
            if case .protocolTweaks = $0 {
                return true
            }
            return false
        }
    }

    private func hasConfiguration(_ entry: AntiCensorshipOptionsEntryType) -> Bool {
        entry.makeSecondaryEntries().contains {
            if case .wgUnlockMenu = $0 {
                return true
            }
            return false
        }
    }
}

private final class StubAntiCensorshipManaging: AntiCensorshipManaging, @unchecked Sendable {
    let unlockParams: [UnblockWgParams] = []
    var protocolTweaksMode: ProtocolTweaksMode = .auto
    var useProtocolTweaks = false
    var serverRoutingType: ServerRoutingType = .auto
    var selectedWgParam: UnblockWgParams?

    var protocolTweaksModeUpdates: AsyncStream<ProtocolTweaksMode> { emptyStream() }
    var useProtocolTweaksUpdates: AsyncStream<Bool> { emptyStream() }
    var serverRoutingTypeUpdates: AsyncStream<ServerRoutingType> { emptyStream() }
    var selectedWgParamUpdates: AsyncStream<UnblockWgParams?> { emptyStream() }

    func setProtocolTweaksMode(_ value: ProtocolTweaksMode) {
        protocolTweaksMode = value
    }

    func setServerRoutingType(_ value: ServerRoutingType) {
        serverRoutingType = value
    }

    func setWgParameter(withId id: String) {}

    private func emptyStream<Value>() -> AsyncStream<Value> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private struct StubLogStoring: LogStoring {
    func logI(_ tag: String, _ message: String) {}
    func logE(_ tag: String, _ message: String) {}
    func logD(_ tag: String, _ message: String) {}
    func getLogData() async throws -> String { "" }
}

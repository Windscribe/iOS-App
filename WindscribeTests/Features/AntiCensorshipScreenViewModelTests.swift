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

    private func makeViewModel(
        preferencesReading: any PreferencesReading = StubPreferencesReading(),
        preferencesWriting: any PreferencesWriting = MockPreferencesWriting()
    ) -> AntiCensorshipScreenViewModel {
        AntiCensorshipScreenViewModel(
            antiCensorshipManaging: StubAntiCensorshipManaging(),
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
}

private final class StubAntiCensorshipManaging: AntiCensorshipManaging, @unchecked Sendable {
    let unlockParams: [UnblockWgParams] = []
    var useProtocolTweaks = false
    var serverRoutingType: ServerRoutingType = .auto
    var selectedWgParam: UnblockWgParams?

    var useProtocolTweaksUpdates: AsyncStream<Bool> { emptyStream() }
    var serverRoutingTypeUpdates: AsyncStream<ServerRoutingType> { emptyStream() }
    var selectedWgParamUpdates: AsyncStream<UnblockWgParams?> { emptyStream() }

    func setUseProtocolTweaks(_ value: Bool) {
        useProtocolTweaks = value
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

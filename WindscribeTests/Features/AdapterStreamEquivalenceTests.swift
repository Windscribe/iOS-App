//
//  AdapterStreamEquivalenceTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-05-07.
//  Copyright © 2026 Windscribe. All rights reserved.
//
//  Behavioral-equivalence tests for the three live Combine→AsyncStream
//  adapters in `Windscribe/Services/Protocols/`. Each adapter wraps a
//  legacy `CurrentValueSubject` and exposes an `AsyncStream`; these tests
//  pin the contract the adapter promises:
//   1. Initial subscription yields the subject's current value.
//   2. Subsequent `subject.send(...)` yields are forwarded in order.
//   3. The property is computed — each access creates an independent stream.
//
//  M4 PR 2+ extend `VPNConnecting` with `statusUpdates`; the same shape of
//  test should land alongside that adapter.
//

import Testing
import Foundation
import Combine
import NetworkExtension
@testable import Windscribe

@Suite("Combine→AsyncStream adapter equivalence")
struct AdapterStreamEquivalenceTests {

    // MARK: - LegacyLookAndFeelObserver (M0)

    @Test("LookAndFeel: initial subscription yields current value")
    func lookAndFeel_initialValueYielded() async {
        let repo = StubLookAndFeelRepository(initialDarkMode: true)
        let observer = LegacyLookAndFeelObserver(repository: repo)

        var iterator = observer.darkModeUpdates.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first == true)
    }

    @Test("LookAndFeel: subsequent updates forwarded in order")
    func lookAndFeel_orderedUpdates() async {
        let repo = StubLookAndFeelRepository(initialDarkMode: true)
        let observer = LegacyLookAndFeelObserver(repository: repo)

        var iterator = observer.darkModeUpdates.makeAsyncIterator()
        let initial = await iterator.next()
        repo.isDarkModeSubject.send(false)
        repo.isDarkModeSubject.send(true)
        repo.isDarkModeSubject.send(false)
        let v1 = await iterator.next()
        let v2 = await iterator.next()
        let v3 = await iterator.next()

        #expect(initial == true)
        #expect(v1 == false)
        #expect(v2 == true)
        #expect(v3 == false)
    }

    @Test("LookAndFeel: each access creates an independent stream")
    func lookAndFeel_independentStreamsPerAccess() async {
        let repo = StubLookAndFeelRepository(initialDarkMode: true)
        let observer = LegacyLookAndFeelObserver(repository: repo)

        var streamA = observer.darkModeUpdates.makeAsyncIterator()
        var streamB = observer.darkModeUpdates.makeAsyncIterator()
        let firstA = await streamA.next()
        let firstB = await streamB.next()
        #expect(firstA == true)
        #expect(firstB == true)

        repo.isDarkModeSubject.send(false)
        let nextA = await streamA.next()
        let nextB = await streamB.next()
        #expect(nextA == false)
        #expect(nextB == false)
    }

    // MARK: - LegacyServerProvider (M3)

    @Test("ServerProviding: initial subscription yields current value")
    func serverProviding_initialValueYielded() async {
        let seeded = [makeLocation(id: 1, name: "A")]
        let repo = StubLocationListRepository(initial: seeded)
        let provider = LegacyServerProvider(legacy: repo)

        var iterator = provider.locationUpdates.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first?.first?.id == 1)
    }

    @Test("ServerProviding: subsequent updates forwarded in order")
    func serverProviding_orderedUpdates() async {
        let repo = StubLocationListRepository(initial: [])
        let provider = LegacyServerProvider(legacy: repo)

        var iterator = provider.locationUpdates.makeAsyncIterator()
        let initial = await iterator.next()
        repo.locationListSubject.send([makeLocation(id: 1, name: "A")])
        repo.locationListSubject.send([makeLocation(id: 2, name: "B")])
        let v1 = await iterator.next()
        let v2 = await iterator.next()

        #expect(initial?.isEmpty == true)
        #expect(v1?.first?.id == 1)
        #expect(v2?.first?.id == 2)
    }

    // MARK: - LegacySessionProvider (M3)

    @Test("SessionProviding: initial subscription yields current value")
    func sessionProviding_initialValueYielded() async {
        let repo = StubUserSessionRepository(initial: nil)
        let provider = LegacySessionProvider(legacy: repo)

        var iterator = provider.sessionUpdates.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first ?? nil == nil)
    }

    @Test("SessionProviding: subsequent updates forwarded in order")
    func sessionProviding_orderedUpdates() async {
        let repo = StubUserSessionRepository(initial: nil)
        let provider = LegacySessionProvider(legacy: repo)

        var iterator = provider.sessionUpdates.makeAsyncIterator()
        let initial = await iterator.next()
        let s1 = makeSession(authHash: "a")
        let s2 = makeSession(authHash: "b")
        repo.sessionModelSubject.send(s1)
        repo.sessionModelSubject.send(s2)
        repo.sessionModelSubject.send(nil)
        let v1 = await iterator.next()
        let v2 = await iterator.next()
        let v3 = await iterator.next()

        #expect(initial ?? nil == nil)
        #expect(v1??.sessionAuthHash == "a")
        #expect(v2??.sessionAuthHash == "b")
        #expect(v3 ?? nil == nil)
    }

    // MARK: - LegacyVPNConnector (M4 PR2)

    @Test("VPNConnecting: initial subscription yields current status (.disconnected when nil)")
    func vpnConnecting_initialValueYielded_nil() async {
        let stateRepo = StubVPNStateRepository(initial: nil)
        let connector = LegacyVPNConnector(legacy: NoopVPNManager(), stateRepository: stateRepo)

        var iterator = connector.statusUpdates.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first.map(neStatus) == .disconnected)
    }

    @Test("VPNConnecting: initial subscription yields current status when seeded")
    func vpnConnecting_initialValueYielded_seeded() async {
        let stateRepo = StubVPNStateRepository(initial: makeInfo(status: .connected))
        let connector = LegacyVPNConnector(legacy: NoopVPNManager(), stateRepository: stateRepo)

        var iterator = connector.statusUpdates.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first.map(neStatus) == .connected)
    }

    @Test("VPNConnecting: subsequent status changes forwarded in order")
    func vpnConnecting_orderedUpdates() async {
        let stateRepo = StubVPNStateRepository(initial: nil)
        let connector = LegacyVPNConnector(legacy: NoopVPNManager(), stateRepository: stateRepo)

        var iterator = connector.statusUpdates.makeAsyncIterator()
        let initial = await iterator.next()
        stateRepo.vpnInfo.send(makeInfo(status: .connecting))
        stateRepo.vpnInfo.send(makeInfo(status: .connected))
        stateRepo.vpnInfo.send(makeInfo(status: .disconnecting))
        stateRepo.vpnInfo.send(nil)
        let v1 = await iterator.next()
        let v2 = await iterator.next()
        let v3 = await iterator.next()
        let v4 = await iterator.next()

        #expect(initial.map(neStatus) == .disconnected)
        #expect(v1.map(neStatus) == .connecting)
        #expect(v2.map(neStatus) == .connected)
        #expect(v3.map(neStatus) == .disconnecting)
        #expect(v4.map(neStatus) == .disconnected)
    }
}

// MARK: - Helpers

private func makeLocation(id: Int, name: String) -> LocationModel {
    LocationModel(
        id: id, name: name, countryCode: "US", shortName: "ts",
        sortOrder: 0, continent: "NA", datacenters: []
    )
}

private func makeSession(authHash: String) -> SessionModel {
    SessionModel(
        sessionAuthHash: authHash,
        username: "u", userId: "1",
        email: "", emailStatus: false,
        trafficUsed: 0, trafficMax: 0,
        status: 1, billingPlanId: 0, isPremium: false,
        premiumExpiryDate: "", regDate: 0, lastReset: "",
        locRev: 0, locHash: "",
        amneziawgConfigId: "",
        alc: [], sipCount: []
    )
}

private func makeInfo(status: NEVPNStatus) -> VPNConnectionInfo {
    VPNConnectionInfo(
        selectedProtocol: "WireGuard", selectedPort: "443",
        status: status, server: nil, killSwitch: false, onDemand: false
    )
}

/// Pull the wrapped `NEVPNStatus` out of a `VPNConnectionState.vpn(...)`.
/// Returns `nil` for any other case (none expected in these tests).
private func neStatus(_ state: VPNConnectionState) -> NEVPNStatus? {
    if case let .vpn(s) = state { return s }
    return nil
}

// MARK: - Stub repositories
// Minimal protocol conformances driving the subject the adapter reads.
// Methods unrelated to the adapter trap on call.

private final class StubLookAndFeelRepository: LookAndFeelRepositoryType {
    let backgroundChangedTrigger = PassthroughSubject<Void, Never>()
    let isDarkModeSubject: CurrentValueSubject<Bool, Never>
    var isDarkMode: Bool { isDarkModeSubject.value }

    init(initialDarkMode: Bool) {
        self.isDarkModeSubject = CurrentValueSubject<Bool, Never>(initialDarkMode)
    }

    var backgroundEffectConnect: BackgroundEffectType { fatalError("unused in adapter test") }
    var backgroundEffectDisconnect: BackgroundEffectType { fatalError("unused in adapter test") }
    var backgroundCustomConnectPath: String? { nil }
    var backgroundCustomDisconnectPath: String? { nil }
    var backgroundCustomAspectRatio: BackgroundAspectRatioType { fatalError("unused in adapter test") }

    func updateBackgroundEffectConnect(effect _: BackgroundEffectType) {}
    func updateBackgroundEffectDisconnect(effect _: BackgroundEffectType) {}
    func updateBackgroundCustomConnectPath(path _: String) {}
    func updateBackgroundCustomDisconnectPath(path _: String) {}
    func updateBackgroundCustomAspectRatio(aspectRatio _: BackgroundAspectRatioType) {}
}

private final class StubLocationListRepository: LocationListRepository {
    let locationListSubject: CurrentValueSubject<[LocationModel], Never>
    let datacenterListSubject = CurrentValueSubject<[DatacenterModel], Never>([])
    let serverListSubject = CurrentValueSubject<[ServerMachineModel], Never>([])
    let favouriteListSubject = CurrentValueSubject<[FavouriteModel], Never>([])

    var currentLocationModels: [LocationModel] { locationListSubject.value }
    var currentDatacenterModels: [DatacenterModel] { [] }
    var currentServerModels: [ServerMachineModel] { [] }
    var currentFavouriteModels: [FavouriteModel] { [] }

    init(initial: [LocationModel]) {
        self.locationListSubject = CurrentValueSubject<[LocationModel], Never>(initial)
    }

    func updateLocations() async throws {}
    func updatedServerList() async throws {}
    func updateInventory(with _: ServerInventoryModel) {}
    func updateAll() async throws {}
    func updateRegions(with _: [ExportedRegion]) {}
    func getLocation(by _: Int) -> LocationModel? { nil }
    func getDatacenter(by _: Int) -> DatacenterModel? { nil }
    func getDatacenters(for _: Int) -> [DatacenterModel] { [] }
    func getServers(for _: Int) -> [ServerMachineModel] { [] }
    func getRandomServer(for _: Int) -> ServerMachineModel? { nil }
    func getFavorite(from _: String) -> FavouriteModel? { nil }
    func removeFavorite(with _: String) {}
    func removeFavorite(with _: Int) {}
    func saveFavorite(for _: FavouriteModel) {}
    func getDatacenterPinnedHotname(for _: Int) -> String? { nil }
    func saveLastConnectedHost(for _: String, with _: Int) {}
    func updateAllIfEmpty() async throws {}
}

private final class StubUserSessionRepository: UserSessionRepository {
    let sessionModelSubject: CurrentValueSubject<SessionModel?, Never>
    var sessionAuth: String? { nil }
    var sessionModel: SessionModel? { sessionModelSubject.value }
    var oldSessionModel: SessionModel? { nil }

    init(initial: SessionModel?) {
        self.sessionModelSubject = CurrentValueSubject<SessionModel?, Never>(initial)
    }

    func update(session _: SessionModel) async {}
    func updateSessionAuth(with _: String?) {}
    func clearSession() {}
    func canAccesstoProLocation(location _: LocationModel) -> Bool { false }
    func canAccesstoProLocation(locationId _: Int) -> Bool { false }
    func syncSession() async -> Bool { false }
    func clean() {}
}

private final class StubVPNStateRepository: VPNStateRepository {
    let vpnInfo: CurrentValueSubject<VPNConnectionInfo?, Never>
    let configurationStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    let connectionStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    var configurationState: ConfigurationState { .initial }
    var isFromProtocolFailover: Bool { false }
    var isFromProtocolChange: Bool { false }
    var untrustedOneTimeOnlySSID: String { "" }
    var lastConnectionStatus: NEVPNStatus { vpnInfo.value?.status ?? .disconnected }
    var lastConnectionType: ConnectionType { .user }
    var isEmergencyConnection: Bool { false }

    init(initial: VPNConnectionInfo?) {
        self.vpnInfo = CurrentValueSubject<VPNConnectionInfo?, Never>(initial)
    }

    func setUntrustedOneTimeOnlySSID(_: String) {}
    func setIsFromProtocolFailover(_: Bool) {}
    func setIsFromProtocolChange(_: Bool) {}
    func setLastConnectionStatus(_: NEVPNStatus) {}
    func setConfigurationState(_: ConfigurationState) {}
    func setLastConnectionType(_: ConnectionType) {}
    func isDisconnected() -> Bool { vpnInfo.value?.status == .disconnected }
    func isConnecting() -> Bool { vpnInfo.value?.status == .connecting }
    func isConnected() -> Bool { vpnInfo.value?.status == .connected }
    func getStatus() -> AnyPublisher<NEVPNStatus, Never> {
        vpnInfo.map { $0?.status ?? .disconnected }.eraseToAnyPublisher()
    }
}

/// Minimal VPNManager stub. The status-stream test path doesn't touch
/// any of these methods; trap on call so a misuse surfaces loudly.
private final class NoopVPNManager: VPNManager {
    let showFailedPinIpTrigger = PassthroughSubject<Void, Never>()

    func configureForConnectionState() {}
    func isActive() async -> Bool { false }
    func updateOnDemandRules() {}
    func resetProfiles() async {}
    func disconnectFromViewModel() -> AnyPublisher<VPNConnectionState, Error> {
        fatalError("unused in status-stream test")
    }
    func connectFromViewModel(locationId _: String, proto _: ProtocolPort) -> AnyPublisher<VPNConnectionState, Error> {
        fatalError("unused in status-stream test")
    }
    func connectFromViewModel(locationId _: String, proto _: ProtocolPort, connectionType _: ConnectionType) -> AnyPublisher<VPNConnectionState, Error> {
        fatalError("unused in status-stream test")
    }
    func simpleDisableConnection() {}
    func simpleEnableConnection() {}
    func makeUserSettings() -> VPNUserSettings { fatalError("unused in status-stream test") }
}

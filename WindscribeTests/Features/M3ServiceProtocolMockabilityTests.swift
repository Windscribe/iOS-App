//
//  M3ServiceProtocolMockabilityTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("M3 service protocols are mockable")
struct M3ServiceProtocolMockabilityTests {

    @Test("VPNConnecting mock covers connect + disconnect")
    func vpnConnecting() async throws {
        let mock = MockVPNConnecting()
        try await mock.connect(locationId: "ord", proto: ("wireguard", "443"))
        try await mock.disconnect()
        #expect(mock.connectCallCount == 1)
        #expect(mock.disconnectCallCount == 1)
    }

    @Test("ServerProviding mock yields seeded values via the stream")
    func serverProviding() async throws {
        let seeded = LocationModel(
            id: 1, name: "Test", countryCode: "US", shortName: "ts",
            sortOrder: 0, continent: "NA", datacenters: []
        )
        let mock = MockServerProviding(initial: [seeded])
        #expect(mock.locations.count == 1)

        var iterator = mock.locationUpdates.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first?.first?.id == 1)
    }

    @Test("CredentialStoring mock returns seeded values")
    func credentialStoring() async throws {
        let mock = MockCredentialStoring(
            openVPN: ServerCredentialsModel(username: "u", password: "p"),
            ikev2: nil
        )
        #expect(mock.openVPNCredentials?.username == "u")
        #expect(mock.ikev2Credentials == nil)

        try await mock.refreshOpenVPNCredentials()
        try await mock.refreshIKEv2Credentials()
        #expect(mock.refreshCallCount == 2)
    }

    @Test("PreferencesReading mock returns seeded values")
    func preferencesReading() {
        let mock = MockPreferencesReading(
            killSwitchEnabled: true,
            allowLAN: false,
            selectedProtocol: "wireguard",
            selectedPort: "443"
        )
        #expect(mock.killSwitchEnabled == true)
        #expect(mock.allowLAN == false)
        #expect(mock.selectedProtocol == "wireguard")
        #expect(mock.selectedPort == "443")
    }

    @Test("SessionProviding mock yields current session via the stream")
    func sessionProviding() async {
        let mock = MockSessionProviding(initial: nil)
        #expect(mock.session == nil)

        var iterator = mock.sessionUpdates.makeAsyncIterator()
        let first = await iterator.next()
        // First emission is the current value (nil here).
        #expect(first ?? nil == nil)
    }
}

// MARK: - Mocks

final class MockVPNConnecting: VPNConnecting, @unchecked Sendable {
    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    var statusUpdates: AsyncStream<VPNConnectionState> {
        AsyncStream { $0.finish() }
    }

    func connect(locationId: String, proto: ProtocolPort) async throws {
        connectCallCount += 1
    }

    func disconnect() async throws {
        disconnectCallCount += 1
    }
}

final class MockServerProviding: ServerProviding, @unchecked Sendable {
    private(set) var locations: [LocationModel]
    private var continuation: AsyncStream<[LocationModel]>.Continuation?

    init(initial: [LocationModel] = []) {
        self.locations = initial
    }

    var locationUpdates: AsyncStream<[LocationModel]> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.locations)
        }
    }

    func send(_ value: [LocationModel]) {
        locations = value
        continuation?.yield(value)
    }
}

final class MockCredentialStoring: CredentialStoring, @unchecked Sendable {
    let openVPNCredentials: ServerCredentialsModel?
    let ikev2Credentials: ServerCredentialsModel?
    private(set) var refreshCallCount = 0

    init(openVPN: ServerCredentialsModel?, ikev2: ServerCredentialsModel?) {
        self.openVPNCredentials = openVPN
        self.ikev2Credentials = ikev2
    }

    func refreshOpenVPNCredentials() async throws { refreshCallCount += 1 }
    func refreshIKEv2Credentials() async throws { refreshCallCount += 1 }
}

final class MockPreferencesReading: PreferencesReading, @unchecked Sendable {
    let killSwitchEnabled: Bool
    let allowLAN: Bool
    let selectedProtocol: String?
    let selectedPort: String?

    init(killSwitchEnabled: Bool, allowLAN: Bool, selectedProtocol: String?, selectedPort: String?) {
        self.killSwitchEnabled = killSwitchEnabled
        self.allowLAN = allowLAN
        self.selectedProtocol = selectedProtocol
        self.selectedPort = selectedPort
    }
}

final class MockSessionProviding: SessionProviding, @unchecked Sendable {
    private(set) var session: SessionModel?
    private var continuation: AsyncStream<SessionModel?>.Continuation?

    init(initial: SessionModel?) {
        self.session = initial
    }

    var sessionUpdates: AsyncStream<SessionModel?> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.session)
        }
    }

    func send(_ value: SessionModel?) {
        session = value
        continuation?.yield(value)
    }
}

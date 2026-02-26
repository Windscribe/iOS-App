//
//  MockVPNManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import NetworkExtension

@testable import Windscribe

class MockVPNManager: VPNManager {

    // Mock vars
    var mockStatus: NEVPNStatus = .disconnected
    var showFailedPinIpTrigger = PassthroughSubject<Void, Never>()

    // Connection tracking
    var connectFromViewModelCallCount = 0
    var lastConnectLocationId: String?
    var lastConnectProto: ProtocolPort?
    var lastConnectConnectionType: ConnectionType?
    var mockConnectionStates: [VPNConnectionState] = [.vpn(.connecting), .vpn(.connected)]
    var mockConnectionError: Error?

    func configureForConnectionState() {
    }

    func updateOnDemandRules() {

    }

    func resetProfiles() async {

    }

    func isActive() async -> Bool {
        false
    }

    func disconnectFromViewModel() -> AnyPublisher<Windscribe.VPNConnectionState, any Error> {
        let subject = PassthroughSubject<VPNConnectionState, Error>()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let error = self.mockConnectionError {
                subject.send(completion: .failure(error))
            } else {
                subject.send(.vpn(.disconnected))
                subject.send(completion: .finished)
            }
        }

        return subject.eraseToAnyPublisher()
    }

    func connectFromViewModel(locationId: String, proto: Windscribe.ProtocolPort, connectionType: Windscribe.ConnectionType) -> AnyPublisher<Windscribe.VPNConnectionState, any Error> {
        connectFromViewModelCallCount += 1
        lastConnectLocationId = locationId
        lastConnectProto = proto
        lastConnectConnectionType = connectionType

        let subject = PassthroughSubject<VPNConnectionState, Error>()

        // Emit states asynchronously to simulate real connection flow
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let error = self.mockConnectionError {
                subject.send(completion: .failure(error))
            } else {
                // Emit each state in sequence
                for state in self.mockConnectionStates {
                    subject.send(state)
                }
                subject.send(completion: .finished)
            }
        }

        return subject.eraseToAnyPublisher()
    }

    func simpleDisableConnection() {

    }

    func simpleEnableConnection() {

    }

    func makeUserSettings() -> Windscribe.VPNUserSettings {
        VPNUserSettings(killSwitch: false,
                        allowLan: false,
                        isRFC: false,
                        isCircumventCensorshipEnabled: false,
                        onDemandRules: [])
    }
}

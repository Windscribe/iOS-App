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
        PassthroughSubject<VPNConnectionState, Error>().eraseToAnyPublisher()
    }

    func connectFromViewModel(locationId: String, proto: Windscribe.ProtocolPort, connectionType: Windscribe.ConnectionType) -> AnyPublisher<Windscribe.VPNConnectionState, any Error> {
        PassthroughSubject<VPNConnectionState, Error>().eraseToAnyPublisher()
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

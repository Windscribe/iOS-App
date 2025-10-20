//
//  MockVPNManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

@testable import Windscribe
import NetworkExtension

class MockVPNManager: VPNManager {
    var configurationState: Windscribe.ConfigurationState = .initial
    var vpnInfo = CurrentValueSubject<Windscribe.VPNConnectionInfo?, Never>(nil)
    var connectionStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    var isFromProtocolFailover: Bool = false
    var isFromProtocolChange: Bool = false
    var untrustedOneTimeOnlySSID: String  = ""

    func configureForConnectionState() {
    }

    func setUntrustedOneTimeOnlySSID(_ value: String) {
        untrustedOneTimeOnlySSID = value
    }

    func setIsFromProtocolFailover(_ value: Bool) {
        isFromProtocolFailover = value
    }

    func setIsFromProtocolChange(_ value: Bool) {
        isFromProtocolChange = value
    }

    func updateOnDemandRules() {

    }

    func resetProfiles() async {

    }

    func isDisconnected() -> Bool {
        false
    }

    func isConnecting() -> Bool {
        false
    }

    func isConnected() -> Bool {
        false
    }

    func getStatus() -> AnyPublisher<NEVPNStatus, Never> {
        PassthroughSubject<NEVPNStatus, Never>().eraseToAnyPublisher()
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

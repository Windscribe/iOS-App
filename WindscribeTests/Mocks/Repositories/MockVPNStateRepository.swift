//
//  MockVPNStateRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 20/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import NetworkExtension

@testable import Windscribe

class MockVPNStateRepository: VPNStateRepository {
    // Mock vars
    var mockStatus: NEVPNStatus = .disconnected

    // VPNStateRepository protocol properties
    var configurationState: ConfigurationState = .initial
    var vpnInfo = CurrentValueSubject<VPNConnectionInfo?, Never>(nil)
    var configurationStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    var connectionStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    var isFromProtocolFailover: Bool = false
    var isFromProtocolChange: Bool = false
    var untrustedOneTimeOnlySSID: String = ""
    var lastConnectionStatus: NEVPNStatus = .disconnected

    // VPNStateRepository protocol methods
    func setUntrustedOneTimeOnlySSID(_ value: String) {
        untrustedOneTimeOnlySSID = value
    }

    func setIsFromProtocolFailover(_ value: Bool) {
        isFromProtocolFailover = value
    }

    func setIsFromProtocolChange(_ value: Bool) {
        isFromProtocolChange = value
    }

    func setLastConnectionStatus(_ value: NEVPNStatus) {
        lastConnectionStatus = value
    }

    func setConfigurationState(_ value: ConfigurationState) {
        configurationState = value
        configurationStateUpdatedTrigger.send()
    }

    func isDisconnected() -> Bool {
        mockStatus == .disconnected
    }

    func isConnecting() -> Bool {
        mockStatus == .connecting
    }

    func isConnected() -> Bool {
        mockStatus == .connected
    }

    func getStatus() -> AnyPublisher<NEVPNStatus, Never> {
        PassthroughSubject<NEVPNStatus, Never>().eraseToAnyPublisher()
    }
}

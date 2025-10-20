//
//  VPNStateRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
import NetworkExtension

enum ConfigurationState {
    case configuring
    case disabling
    case initial
    case testing
}

protocol VPNStateRepository {
    var configurationState: ConfigurationState { get }
    var vpnInfo: CurrentValueSubject<VPNConnectionInfo?, Never> { get }
    var configurationStateUpdatedTrigger: PassthroughSubject<Void, Never> { get }
    var connectionStateUpdatedTrigger: PassthroughSubject<Void, Never> { get }
    var isFromProtocolFailover: Bool { get }
    var isFromProtocolChange: Bool { get }
    var untrustedOneTimeOnlySSID: String { get }
    var lastConnectionStatus: NEVPNStatus { get }

    // Set Methods
    func setUntrustedOneTimeOnlySSID(_ value: String)
    func setIsFromProtocolFailover(_ value: Bool)
    func setIsFromProtocolChange(_ value: Bool)
    func setLastConnectionStatus(_ value: NEVPNStatus)
    func setConfigurationState(_ value: ConfigurationState)

    // Check Status Methods
    func isDisconnected() -> Bool
    func isConnecting() -> Bool
    func isConnected() -> Bool
    func getStatus() -> AnyPublisher<NEVPNStatus, Never>
}

class VPNStateRepositoryImpl: VPNStateRepository {
    let logger: FileLogger

    /// A lock used to synchronize access to the configuration state.
    private let configureStateLock = NSLock()

    /// Represents the configuration state of the VPN.
    private var _configurationState = ConfigurationState.initial

    var configurationState: ConfigurationState {
        get {
            configureStateLock.lock()
            defer { configureStateLock.unlock() }
            return _configurationState
        }
        set {
            configureStateLock.lock()
            _configurationState = newValue
            configureStateLock.unlock()
            configurationStateUpdatedTrigger.send()
        }
    }

    var configurationStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    var connectionStateUpdatedTrigger = PassthroughSubject<Void, Never>()
    var vpnInfo = CurrentValueSubject<VPNConnectionInfo?, Never>(nil)

    var lastConnectionStatus: NEVPNStatus = .disconnected

    var isFromProtocolFailover: Bool = false
    var isFromProtocolChange: Bool = false

    var untrustedOneTimeOnlySSID: String = ""

    init(logger: FileLogger) {
        self.logger = logger
    }

    func setLastConnectionStatus(_ value: NEVPNStatus) {
        lastConnectionStatus = value
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

    func setConfigurationState(_ value: ConfigurationState) {
        configurationState = value
    }

    func isConnected() -> Bool {
        vpnInfo.value?.status == .connected
    }

    func isConnecting() -> Bool {
        vpnInfo.value?.status == .connecting
    }

    func isDisconnected() -> Bool {
        vpnInfo.value?.status == .disconnected
    }

    func isDisconnecting() -> Bool {
        vpnInfo.value?.status == .disconnecting
    }

    func isInvalid() -> Bool {
        vpnInfo.value?.status == .invalid
    }

    func connectionStatus() -> NEVPNStatus {
        return vpnInfo.value?.status ?? NEVPNStatus.disconnected
    }

    /// Returns an observable that emits the VPN status with a debounce and custom mapping logic.
    /// This function observes changes in the `vpnInfo` and applies a debounce to avoid rapid updates.
    ///
    /// - Returns: An `Observable` that emits the VPN status as an `NEVPNStatus` value.
    func getStatus() -> AnyPublisher<NEVPNStatus, Never> {
        return vpnInfo
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .compactMap { $0 }
            .map { [weak self] info -> NEVPNStatus in
                guard let self = self else { return .invalid }

                switch self.configurationState {
                case .configuring:
                    self.logger.logD("VPNConfiguration", "vpnInfo update to: configuring -> connecting")
                    return NEVPNStatus.connecting
                case .disabling:
                    self.logger.logD("VPNConfiguration", "vpnInfo update to: disabling -> disconnecting")
                    return NEVPNStatus.disconnecting
                case .initial:
                    self.logger.logD("VPNConfiguration", "vpnInfo update to: Initial -> \(info.description)")
                    return info.status
                case .testing:
                    return info.status
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

//
//	ConnectionsViewModel.swift
//	Windscribe
//
//	Created by Thomas on 26/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import Network
import Combine
import UIKit

protocol ConnectionsViewModelType {
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var isCircumventCensorshipEnabled: CurrentValueSubject<Bool, Never> { get }
    var shouldShowCustomDNSOption: CurrentValueSubject<Bool, Never> { get }
    var languageUpdatedTrigger: PassthroughSubject<Void, Never> { get }

    func updateChangeFirewallStatus()
    func updateChangeKillSwitchStatus()
    func updateChangeKillSwitchStatus(status: Bool)
    func updateChangeAllowLanStatus()
    func updateChangeAllowLanStatus(status: Bool)
    func updateAutoSecureNetworkStatus()
    func updateCircumventCensorshipStatus(status: Bool)
    func updatePort(value: String)
    func updateProtocol(value: String)
    func updateConnectionMode(value: ConnectionModeType)
    func updateConnectedDNS(type: ConnectedDNSType)

    func getCircumventCensorshipStatus() -> Bool
    func getFirewallStatus() -> Bool
    func getKillSwitchStatus() -> Bool
    func getAllowLanStatus() -> Bool
    func getAutoSecureNetworkStatus() -> Bool

    func getCurrentConnectionMode() -> ConnectionModeType
    func getCurrentConnectedDNS() -> ConnectedDNSType

    func getCurrentProtocol() -> String
    func getCurrentPort() -> String

    func getConnectedDNSValue() -> String

    func getProtocols() -> [String]
    func getPorts() -> [String]
    func getPort(by protocolType: String) -> [String]

    func saveConnectedDNSValue(value: String, completion: @escaping (_ isValid: Bool) -> Void)

    func getCurrentEgressProtocol() -> String
    func getCurrentIngressProtocol() -> String
    func updateEgressProtocol(value: String)
    func updateIngressProtocol(value: String)
    func getIpStackOptions() -> [String]
}

class ConnectionsViewModel: ConnectionsViewModelType {

    // MARK: - Dependencies
    private let preferences: Preferences
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let portMapRepository: PortMapRepository
    private let connectivity: ConnectivityManager
    private let networkRepository: WifiNetworkRepository
    private let languageManager: LanguageManager
    private let protocolManager: ProtocolManagerType
    private let dnsSettingsManager: DNSSettingsManagerType
    private var cancellables = Set<AnyCancellable>()

    private var currentProtocol = CurrentValueSubject<String, Never>(DefaultValues.protocol)
    private var currentPort = CurrentValueSubject<String, Never>(DefaultValues.port)
    private var firewall = CurrentValueSubject<Bool, Never>(DefaultValues.firewallMode)
    private var killSwitch = CurrentValueSubject<Bool, Never>(DefaultValues.killSwitch)
    private var allowLane = CurrentValueSubject<Bool, Never>(DefaultValues.allowLANMode)
    private var autoSecure = CurrentValueSubject<Bool, Never>(DefaultValues.autoSecureNewNetworks)
    private var connectionMode = ConnectionModeType.defaultValue()
    private var connectedDNS = ConnectedDNSType.defaultValue()
    private var egressProtocol = CurrentValueSubject<String, Never>(DefaultValues.ipStack)
    private var ingressProtocol = CurrentValueSubject<String, Never>(DefaultValues.ipStack)

    let isCircumventCensorshipEnabled = CurrentValueSubject<Bool, Never>(DefaultValues.circumventCensorship)
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let shouldShowCustomDNSOption = CurrentValueSubject<Bool, Never>(true)
    let languageUpdatedTrigger = PassthroughSubject<Void, Never>()

    init(preferences: Preferences,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         portMapRepository: PortMapRepository,
         connectivity: ConnectivityManager,
         networkRepository: WifiNetworkRepository,
         languageManager: LanguageManager,
         protocolManager: ProtocolManagerType,
         dnsSettingsManager: DNSSettingsManagerType) {
        self.preferences = preferences
        self.lookAndFeelRepository = lookAndFeelRepository
        self.portMapRepository = portMapRepository
        self.connectivity = connectivity
        self.networkRepository = networkRepository
        self.languageManager = languageManager
        self.protocolManager = protocolManager
        self.dnsSettingsManager = dnsSettingsManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        loadData()
    }

    private func loadData() {
        preferences.getSelectedProtocol().sink { [weak self] data in
            self?.currentProtocol.send(data ?? DefaultValues.protocol)
        }.store(in: &cancellables)
        preferences.getSelectedPort().sink { [weak self] data in
            self?.currentPort.send(data ?? DefaultValues.port)
        }.store(in: &cancellables)
        preferences.getFirewallMode().sink { [weak self] data in
            self?.firewall.send(data ?? DefaultValues.firewallMode)
        }.store(in: &cancellables)
        preferences.getKillSwitch().sink { [weak self] data in
            self?.killSwitch.send(data ?? DefaultValues.killSwitch)
        }.store(in: &cancellables)
        preferences.getAllowLAN().sink { [weak self] data in
            self?.allowLane.send(data ?? DefaultValues.allowLANMode)
        }.store(in: &cancellables)
        preferences.getAutoSecureNewNetworks().sink { [weak self] data in
            self?.autoSecure.send(data ?? DefaultValues.autoSecureNewNetworks)
        }.store(in: &cancellables)
        preferences.getConnectionMode().sink { [weak self] data in
            self?.connectionMode = ConnectionModeType(fieldValue: data ?? DefaultValues.connectionMode)
        }.store(in: &cancellables)
        preferences.getConnectedDNSObservable().sink { [weak self] data in
            self?.connectedDNS = ConnectedDNSType(fieldValue: data ?? DefaultValues.connectedDNS)
        }.store(in: &cancellables)
        preferences.getCircumventCensorshipEnabled().sink { [weak self] data in
            self?.isCircumventCensorshipEnabled.send(data)
        }.store(in: &cancellables)
        preferences.getEgressProtocolPreference().sink { [weak self] data in
            self?.egressProtocol.send(data ?? DefaultValues.ipStack)
        }.store(in: &cancellables)
        preferences.getIngressProtocolPreference().sink { [weak self] data in
            self?.ingressProtocol.send(data ?? DefaultValues.ipStack)
        }.store(in: &cancellables)

        let connectionModePublisher = preferences.getConnectionMode()

        let selectedProtocolPublisher = preferences.getSelectedProtocol()

        Publishers.CombineLatest3(connectionModePublisher, selectedProtocolPublisher, connectivity.network)
            .sink { [weak self] (connectionMode, selectedProtocol, network) in
                guard let self = self else { return }
                if network.networkType == .wifi, let currentNetwork = self.networkRepository.getCurrentNetwork(), currentNetwork.preferredProtocolStatus {
                    self.shouldShowCustomDNSOption.send(currentNetwork.preferredProtocol != VPNProtocolType.iKEv2.identifier)
                    return
                }
                if let connectionMode = connectionMode, let selectedProtocol = selectedProtocol {
                    if connectionMode == Fields.Values.manual {
                        self.shouldShowCustomDNSOption.send(selectedProtocol != VPNProtocolType.iKEv2.identifier)
                        return
                    }
                }
                self.shouldShowCustomDNSOption.send(true)
            }
            .store(in: &cancellables)

        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.languageUpdatedTrigger.send(())
            }.store(in: &cancellables)
    }

    func updateChangeFirewallStatus() {
        preferences.saveFirewallMode(firewall: !firewall.value)
    }

    func updateChangeKillSwitchStatus(status: Bool) {
        preferences.saveKillSwitch(killSwitch: status)
    }

    func updateChangeKillSwitchStatus() {
        let status = killSwitch.value
        updateChangeKillSwitchStatus(status: !status)
    }

    func updateChangeAllowLanStatus(status: Bool) {
        preferences.saveAllowLane(mode: status)
    }

    func updateChangeAllowLanStatus() {
        let status = allowLane.value
        updateChangeAllowLanStatus(status: !status)
    }

    func updateAutoSecureNetworkStatus() {
        preferences.saveAutoSecureNewNetworks(autoSecure: !autoSecure.value)
    }

    func getFirewallStatus() -> Bool {
        return firewall.value
    }

    func getKillSwitchStatus() -> Bool {
        return killSwitch.value
    }

    func getAllowLanStatus() -> Bool {
        return allowLane.value
    }

    func getAutoSecureNetworkStatus() -> Bool {
        return autoSecure.value
    }

    func getCurrentConnectionMode() -> ConnectionModeType {
        return ConnectionModeType(fieldValue: preferences.getConnectionModeSync())
    }

    func getCurrentConnectedDNS() -> ConnectedDNSType {
        return ConnectedDNSType(fieldValue: preferences.getConnectedDNS())
    }

    func updateConnectedDNS(type: ConnectedDNSType) {
        preferences.saveConnectedDNS(mode: type.fieldValue)
    }

    func getConnectedDNSValue() -> String {
        preferences.getCustomDNSValue().value
    }

    func saveConnectedDNSValue(value: String, completion: @escaping (_ isValid: Bool) -> Void) {
        dnsSettingsManager.getDNSValue(from: value, opensURL: UIApplication.shared, completionDNS: { dnsValue in
            guard let dnsValue = dnsValue else {
                completion(false)
                return
            }
            if dnsValue.servers.isEmpty {
                completion(false)
                return
            }
            self.preferences.saveCustomDNSValue(value: dnsValue)
            completion(true)
        }, completion: { _ in })
    }

    func updateConnectionMode(value: ConnectionModeType) {
        preferences.saveConnectionMode(mode: value.fieldValue)
        Task {
            await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    func updateProtocol(value: String) {
        preferences.saveSelectedProtocol(selectedProtocol: value)
        if let port = portMapRepository.getPorts(protocolType: value) {
            preferences.saveSelectedPort(port: port[0])
        }
        Task {
            await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    func updatePort(value: String) {
        preferences.saveSelectedPort(port: value)
        Task {
            await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    func getCurrentPort() -> String {
        return preferences.getSelectedPortSync() ?? DefaultValues.port
    }

    func getCurrentProtocol() -> String {
        return preferences.getSelectedProtocolSync() ?? DefaultValues.protocol
    }

    func getPorts() -> [String] {
        return portMapRepository.getPorts(protocolType: getCurrentProtocol()) ?? []
    }

    func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    func getPort(by protocolType: String) -> [String] {
        guard let portsArray = portMapRepository.getPorts(protocolType: protocolType) else { return [] }
        return portsArray
    }

    func updateCircumventCensorshipStatus(status: Bool) {
        preferences.saveCircumventCensorshipStatus(status: status)
        WSNet.instance().advancedParameters().setAPIExtraTLSPadding(status)
    }

    func getCircumventCensorshipStatus() -> Bool {
        preferences.isCircumventCensorshipEnabled()
    }

    func getCurrentEgressProtocol() -> String {
        return displayText(for: preferences.getEgressProtocolPreferenceSync())
    }

    func getCurrentIngressProtocol() -> String {
        return displayText(for: preferences.getIngressProtocolPreferenceSync())
    }

    func updateEgressProtocol(value: String) {
        preferences.saveEgressProtocolPreference(value: fieldValue(for: value))
    }

    func updateIngressProtocol(value: String) {
        preferences.saveIngressProtocolPreference(value: fieldValue(for: value))
    }

    private func displayText(for fieldValue: String) -> String {
        switch fieldValue {
        case Fields.Values.auto:
            return TextsAsset.General.auto
        case Fields.Values.ipv4Only:
            return TextsAsset.General.ipv4Only
        default:
            return TextsAsset.General.ipv4Only
        }
    }

    private func fieldValue(for displayText: String) -> String {
        switch displayText {
        case TextsAsset.General.auto:
            return Fields.Values.auto
        case TextsAsset.General.ipv4Only:
            return Fields.Values.ipv4Only
        default:
            return Fields.Values.ipv4Only
        }
    }

    func getIpStackOptions() -> [String] {
        return TextsAsset.ipStackOptions
    }
}

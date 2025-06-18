//
//	ConnectionsViewModel.swift
//	Windscribe
//
//	Created by Thomas on 26/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import Network
import RxSwift
import UIKit

protocol ConnectionsViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    var isCircumventCensorshipEnabled: BehaviorSubject<Bool> { get }
    var shouldShowCustomDNSOption: BehaviorSubject<Bool> { get }
    var languageUpdatedTrigger: PublishSubject<Void> { get }

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
}

class ConnectionsViewModel: ConnectionsViewModelType {
    // MARK: - Dependencies

    let preferences: Preferences, disposeBag = DisposeBag(), lookAndFeelRepository: LookAndFeelRepositoryType, localDb: LocalDatabase, connectivity: Connectivity, networkRepository: SecuredNetworkRepository, languageManager: LanguageManager, protocolManager: ProtocolManagerType

    private var currentProtocol = BehaviorSubject<String>(value: DefaultValues.protocol)
    private var currentPort = BehaviorSubject<String>(value: DefaultValues.port)
    private var firewall = BehaviorSubject<Bool>(value: DefaultValues.firewallMode)
    private var killSwitch = BehaviorSubject<Bool>(value: DefaultValues.killSwitch)
    private var allowLane = BehaviorSubject<Bool>(value: DefaultValues.allowLANMode)
    private var autoSecure = BehaviorSubject<Bool>(value: DefaultValues.autoSecureNewNetworks)
    private var connectionMode = ConnectionModeType.defaultValue()
    private var connectedDNS = ConnectedDNSType.defaultValue()
    let isCircumventCensorshipEnabled = BehaviorSubject<Bool>(value: DefaultValues.circumventCensorship)
    let isDarkMode: BehaviorSubject<Bool>
    let shouldShowCustomDNSOption = BehaviorSubject<Bool>(value: true)
    let languageUpdatedTrigger = PublishSubject<Void>()

    init(preferences: Preferences, lookAndFeelRepository: LookAndFeelRepositoryType, localDb: LocalDatabase, connectivity: Connectivity, networkRepository: SecuredNetworkRepository, languageManager: LanguageManager, protocolManager: ProtocolManagerType) {
        self.preferences = preferences
        self.lookAndFeelRepository = lookAndFeelRepository
        self.localDb = localDb
        self.connectivity = connectivity
        self.networkRepository = networkRepository
        self.languageManager = languageManager
        self.protocolManager = protocolManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        loadData()
    }

    private func loadData() {
        preferences.getSelectedProtocol().subscribe { [weak self] data in
            self?.currentProtocol.onNext(data ?? DefaultValues.protocol)
        }.disposed(by: disposeBag)
        preferences.getSelectedPort().subscribe { [weak self] data in
            self?.currentPort.onNext(data ?? DefaultValues.port)
        }.disposed(by: disposeBag)
        preferences.getFirewallMode().subscribe { [weak self] data in
            self?.firewall.onNext(data ?? DefaultValues.firewallMode)
        }.disposed(by: disposeBag)
        preferences.getKillSwitch().subscribe { [weak self] data in
            self?.killSwitch.onNext(data ?? DefaultValues.killSwitch)
        }.disposed(by: disposeBag)
        preferences.getAllowLAN().subscribe { [weak self] data in
            self?.allowLane.onNext(data ?? DefaultValues.allowLANMode)
        }.disposed(by: disposeBag)
        preferences.getAutoSecureNewNetworks().subscribe { [weak self] data in
            self?.autoSecure.onNext(data ?? DefaultValues.autoSecureNewNetworks)
        }.disposed(by: disposeBag)
        preferences.getConnectionMode().subscribe { [weak self] data in
            self?.connectionMode = ConnectionModeType(fieldValue: data ?? DefaultValues.connectionMode)
        }.disposed(by: disposeBag)
        preferences.getConnectedDNSObservable().subscribe { [weak self] data in
            self?.connectedDNS = ConnectedDNSType(fieldValue: data ?? DefaultValues.connectedDNS)
        }.disposed(by: disposeBag)
        preferences.getCircumventCensorshipEnabled().subscribe { [weak self] data in
            self?.isCircumventCensorshipEnabled.onNext(data)
        }.disposed(by: disposeBag)
        Observable.combineLatest(preferences.getConnectionMode(), preferences.getSelectedProtocol(), connectivity.network).bind { [weak self] connectionMode, selectedProtocol, network in
            guard let self = self else { return }
            if network.networkType == .wifi, let currentNetwork = self.networkRepository.getCurrentNetwork(), currentNetwork.preferredProtocolStatus {
                self.shouldShowCustomDNSOption.onNext(currentNetwork.preferredProtocol != TextsAsset.iKEv2)
                return
            }
            if let connectionMode = connectionMode, let selectedProtocol = selectedProtocol {
                if connectionMode == Fields.Values.manual {
                    self.shouldShowCustomDNSOption.onNext(selectedProtocol != TextsAsset.iKEv2)
                    return
                }
            }
            self.shouldShowCustomDNSOption.onNext(true)
        }.disposed(by: disposeBag)
        languageManager.activelanguage.subscribe { [weak self] _ in
            self?.languageUpdatedTrigger.onNext(())
        }.disposed(by: disposeBag)
    }

    func updateChangeFirewallStatus() {
        try? preferences.saveFirewallMode(firewall: !firewall.value())
    }

    func updateChangeKillSwitchStatus(status: Bool) {
        preferences.saveKillSwitch(killSwitch: status)
    }

    func updateChangeKillSwitchStatus() {
        guard let status = try? killSwitch.value() else { return }
        updateChangeKillSwitchStatus(status: !status)
    }

    func updateChangeAllowLanStatus(status: Bool) {
        preferences.saveAllowLane(mode: status)
    }

    func updateChangeAllowLanStatus() {
        guard let status = try? allowLane.value() else { return }
        updateChangeAllowLanStatus(status: !status)
    }

    func updateAutoSecureNetworkStatus() {
        try? preferences.saveAutoSecureNewNetworks(autoSecure: !autoSecure.value())
    }

    func getFirewallStatus() -> Bool {
        return (try? firewall.value()) ?? DefaultValues.firewallMode
    }

    func getKillSwitchStatus() -> Bool {
        return (try? killSwitch.value()) ?? DefaultValues.killSwitch
    }

    func getAllowLanStatus() -> Bool {
        return (try? allowLane.value()) ?? DefaultValues.allowLANMode
    }

    func getAutoSecureNetworkStatus() -> Bool {
        return (try? autoSecure.value()) ?? DefaultValues.autoSecureNewNetworks
    }

    func getCurrentConnectionMode() -> ConnectionModeType {
        return connectionMode
    }

    func getCurrentConnectedDNS() -> ConnectedDNSType {
        return connectedDNS
    }

    func updateConnectedDNS(type: ConnectedDNSType) {
        preferences.saveConnectedDNS(mode: type.fieldValue)
    }

    func getConnectedDNSValue() -> String {
        preferences.getCustomDNSValue().value
    }

    func saveConnectedDNSValue(value: String, completion: @escaping (_ isValid: Bool) -> Void) {
        DNSSettingsManager.getDNSValue(from: value, opensURL: UIApplication.shared, completionDNS: { dnsValue in
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
        if let port = localDb.getPorts(protocolType: value) {
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
        return (try? currentPort.value()) ?? DefaultValues.port
    }

    func getCurrentProtocol() -> String {
        return (try? currentProtocol.value()) ?? DefaultValues.protocol
    }

    func getPorts() -> [String] {
        return localDb.getPorts(protocolType: getCurrentProtocol()) ?? []
    }

    func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    func getPort(by protocolType: String) -> [String] {
        guard let portsArray = localDb.getPorts(protocolType: protocolType) else { return [] }
        return portsArray
    }

    func updateCircumventCensorshipStatus(status: Bool) {
        preferences.saveCircumventCensorshipStatus(status: status)
        WSNet.instance().advancedParameters().setAPIExtraTLSPadding(status)
    }

    func getCircumventCensorshipStatus() -> Bool {
        preferences.isCircumventCensorshipEnabled()
    }
}

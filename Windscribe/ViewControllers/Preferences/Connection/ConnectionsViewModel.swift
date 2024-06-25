//
//	ConnectionsViewModel.swift
//	Windscribe
//
//	Created by Thomas on 26/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

enum ConnectionModeType {
    case auto
    case manual

    static func defaultValue() -> ConnectionModeType { ConnectionModeType(fieldValue: DefaultValues.connectionMode) }

    var titleValue: String {
        switch self {
        case .auto:
            TextsAsset.General.auto
        case .manual:
            TextsAsset.General.manual
        }
    }

    var fieldValue: String {
        switch self {
        case .auto:
            Fields.Values.auto
        case .manual:
            Fields.Values.manual
        }
    }
}

extension ConnectionModeType {
    init(fieldValue: String) {
        self = switch fieldValue {
        case Fields.Values.auto:
                .auto
        case Fields.Values.manual:
                .manual
        default:
                .auto
        }
    }

    init(titleValue: String) {
        self = switch titleValue {
        case TextsAsset.General.auto:
                .auto
        case TextsAsset.General.manual:
                .manual
        default:
                .auto
        }
    }
}

protocol ConnectionsViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    var isCircumventCensorshipEnabled: BehaviorSubject<Bool> { get }
    func updateChangeFirewallStatus()
    func updateChangeKillSwitchStatus()
    func updateChangeAllowLanStatus()
    func updateAutoSecureNetworkStatus()
    func updateCircumventCensorshipStatus(status: Bool)
    func updatePort(value: String)
    func updateProtocol(value: String)
    func updateConnectionMode(value: ConnectionModeType)

    func getFirewallStatus() -> Bool
    func getKillSwitchStatus() -> Bool
    func getAllowLanStatus() -> Bool
    func getAutoSecureNetworkStatus() -> Bool

    func currentConnectionModes() -> [String]
    func getCurrentConnectionMode() -> ConnectionModeType

    func getCurrentProtocol() -> String
    func getCurrentPort() -> String

    func getProtocols() -> [String]
    func getPorts() -> [String]

    func getPort(by protocolType: String) -> [String]
}

class ConnectionsViewModel: ConnectionsViewModelType {

    // MARK: - Dependencies
    let preferences: Preferences, disposeBag = DisposeBag(), themeManager: ThemeManager!, localDb: LocalDatabase

    private var currentProtocol = BehaviorSubject<String>(value: DefaultValues.protocol)
    private var currentPort = BehaviorSubject<String>(value: DefaultValues.port)
    private var firewall = BehaviorSubject<Bool>(value: DefaultValues.firewallMode)
    private var killSwitch = BehaviorSubject<Bool>(value: DefaultValues.killSwitch)
    private var allowLane = BehaviorSubject<Bool>(value: DefaultValues.allowLaneMode)
    private var autoSecure = BehaviorSubject<Bool>(value: DefaultValues.autoSecureNewNetworks)
    private var connectionMode = BehaviorSubject<ConnectionModeType>(value: ConnectionModeType.defaultValue())
    var isCircumventCensorshipEnabled = BehaviorSubject<Bool>(value: DefaultValues.circumventCensorship)
    let isDarkMode: BehaviorSubject<Bool>

    init(preferences: Preferences, themeManager: ThemeManager, localDb: LocalDatabase) {
        self.preferences = preferences
        self.themeManager = themeManager
        self.localDb = localDb
        isDarkMode = themeManager.darkTheme
        loadData()
    }

    private func loadData() {
        preferences.getSelectedProtocol().subscribe { data in
            self.currentProtocol.onNext(data ?? DefaultValues.protocol)
        }.disposed(by: disposeBag)
        preferences.getSelectedPort().subscribe { data in
            self.currentPort.onNext(data ?? DefaultValues.port)
        }.disposed(by: disposeBag)
        preferences.getFirewallMode().subscribe { data in
            self.firewall.onNext(data ?? DefaultValues.firewallMode)
        }.disposed(by: disposeBag)
        preferences.getKillSwitch().subscribe { data in
            self.killSwitch.onNext(data ?? DefaultValues.killSwitch)
        }.disposed(by: disposeBag)
        preferences.getAllowLane().subscribe { data in
            self.allowLane.onNext(data ?? DefaultValues.allowLaneMode)
        }.disposed(by: disposeBag)
        preferences.getAutoSecureNewNetworks().subscribe { data in
            self.autoSecure.onNext(data ?? DefaultValues.autoSecureNewNetworks)
        }.disposed(by: disposeBag)
        preferences.getConnectionMode().subscribe { data in
            self.connectionMode.onNext(ConnectionModeType(fieldValue: data ?? DefaultValues.connectionMode))
        }.disposed(by: disposeBag)
        preferences.getCircumventCensorshipEnabled().subscribe { data in
            self.isCircumventCensorshipEnabled.onNext(data)
        }.disposed(by: disposeBag)
    }

    func updateChangeFirewallStatus() {
        try? preferences.saveFirewallMode(firewall: !firewall.value())
    }

    func updateChangeKillSwitchStatus() {
        try? preferences.saveKillSwitch(killSwitch: !killSwitch.value())
    }

    func updateChangeAllowLanStatus() {
        try? preferences.saveAllowLane(mode: !allowLane.value())
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
        return (try? allowLane.value()) ?? DefaultValues.allowLaneMode
    }

    func getAutoSecureNetworkStatus() -> Bool {
        return (try? autoSecure.value()) ?? DefaultValues.autoSecureNewNetworks
    }

    func getCurrentConnectionMode() -> ConnectionModeType {
        return (try? connectionMode.value()) ?? ConnectionModeType.defaultValue()
    }

    func updateConnectionMode(value: ConnectionModeType) {
        preferences.saveConnectionMode(mode: value.fieldValue)
    }

    func currentConnectionModes() -> [String] {
        return [TextsAsset.General.auto, TextsAsset.General.manual]
    }

    func updatePort(value: String) {
        preferences.saveSelectedPort(port: value)
        ConnectionManager.shared.loadProtocols { _ in}
    }

    func updateProtocol(value: String) {
        preferences.saveSelectedProtocol(selectedProtocol: value)
        if let port = localDb.getPorts(protocolType: value) {
            preferences.saveSelectedPort(port: port[0])
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
}

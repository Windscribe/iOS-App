//
//  WifiManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import RealmSwift
import CoreTelephony
import NetworkExtension
import Swinject
import RxSwift

class WifiManager {

    static let shared = WifiManager()
    var wifiNotificationToken: NotificationToken?
    var selectedProtocol: String?
    var selectedPort: String?
    var selectedPreferredProtocol: String?
    var selectedPreferredPort: String?
    var selectedPreferredProtocolStatus: Bool?
    var connectedWifi: WifiNetwork?
    lazy var preferences: Preferences = {
        return Assembler.resolve(Preferences.self)
    }()
    lazy var connectivity: Connectivity = {
        return Assembler.resolve(Connectivity.self)
    }()
    private lazy var localDb = Assembler.resolve(LocalDatabase.self)
    private lazy var logger = Assembler.resolve(FileLogger.self)
    let disposeBag = DisposeBag()
    var selectedAutoSecureNewNetworks = BehaviorSubject<Bool?>(value: DefaultValues.autoSecureNewNetworks)
    var connectionMode = BehaviorSubject<String?>(value: DefaultValues.connectionMode)
    private var wifiNetworks = BehaviorSubject<[WifiNetwork]>(value: [])
    private var observingNetworks = false
    private var initialNetworkFetch = true

    init() {
        observeSavedNetworks()
        observeAutoSecureSettings()
    }

    func getConnectedNetwork() -> WifiNetwork? {
        if connectedWifi?.isInvalidated == true {
            return nil
        }
        return connectedWifi
    }

    private func observeSavedNetworks() {
        logger.logD(self, "Observing saved network list.")
        observingNetworks = true
        localDb.getNetworks().filter {$0.first?.isInvalidated == false}.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] networks in
            self.logger.logD(self, "Network list: \(networks.map {$0.SSID}.joined(separator: ", "))")
            self.wifiNetworks.onNext(networks)
            if self.initialNetworkFetch {
                self.setSelectedPreferences()
            } else {
                self.updateSelectedPreferences()
            }
            self.initialNetworkFetch = false
            self.getNetworkName { wifiSSID in
                self.connectedWifi = networks.filter { $0.SSID == wifiSSID }.first
                if self.connectedWifi == nil {
                    self.saveNewNetwork(wifiSSID: wifiSSID ?? "")
                }
            }
        }, onError: { e in
            self.logger.logE(self, "Error getting network list. \(e)")
        },onCompleted: {
            self.logger.logD(self, "Network list is empty.")
            self.observingNetworks = false
        }).disposed(by: disposeBag)
    }

    private func observeAutoSecureSettings() {
        preferences.getAutoSecureNewNetworks().compactMap {$0}.subscribe(onNext: { autoSecure in
            self.logger.logD(self, "Auto secure network setting: \(autoSecure)")
        }, onError: { e in
            self.logger.logE(self, "Error getting auto secure property. \(e)")
        }, onCompleted: {
            self.logger.logD(self, "Auto secure property is empty.")
        }).disposed(by: disposeBag)
    }

    private func saveNewNetwork(wifiSSID: String) {
        if let autoSecureNewNetworks = try? self.selectedAutoSecureNewNetworks.value() {
            let defaultProtocol = TextsAsset.General.protocols[0]
            let defaultPort = localDb.getPorts(protocolType: defaultProtocol)?.first ?? "443"
            let network = WifiNetwork(SSID: wifiSSID,
                                    status: !autoSecureNewNetworks,
                                    protocolType: defaultProtocol,
                                    port: defaultPort,
                                    preferredProtocol: defaultProtocol,
                                    preferredPort: defaultPort)
            logger.logD(self, "Saving \(wifiSSID) to network list.")
            localDb.saveNetwork(wifiNetwork: network).disposed(by: disposeBag)
            if !observingNetworks {
                observeSavedNetworks()
            }
        }
    }

    func configure() {
        saveCellularNetwork()
        saveCurrentWifiNetworks()
    }

    func setSelectedPreferences() {
        guard let result = getConnectedNetwork() else { return }
        self.selectedPreferredProtocol = result.preferredProtocol
        self.selectedPreferredPort = result.preferredPort
        self.selectedPreferredProtocolStatus = result.preferredProtocolStatus
    }

    func updateSelectedPreferences() {
        guard let result = getConnectedNetwork() else { return }
        if (result.protocolType != self.selectedProtocol) || (result.port != self.selectedPort) {
            self.logger.logE(self, "Selected Protocol Changed. \(result.protocolType):\(result.port)")
             self.selectedProtocol = result.protocolType
             self.selectedPort = result.port
         }
        if selectedPreferredProtocol != result.preferredProtocol {
            self.selectedPreferredProtocol = result.preferredProtocol
        }
        if selectedPreferredPort != result.preferredPort {
            self.selectedPreferredPort = result.preferredPort
        }
        if selectedPreferredProtocolStatus != result.preferredProtocolStatus {
            self.selectedPreferredProtocolStatus = result.preferredProtocolStatus
            if result.preferredProtocolStatus == true {
                self.selectedPreferredProtocol = result.preferredProtocol
                self.selectedPreferredPort = result.preferredPort
            }
        }
    }

    func saveCurrentWifiNetworks() {
        self.getNetworkName { wifiSSID in
            guard let wifiSSID = wifiSSID else { return }
            var defaultProtocol = TextsAsset.General.protocols[0]
            var defaultPort = self.localDb.getPorts(protocolType: defaultProtocol)?.first ?? "443"

            if let suggestedPorts = self.localDb.getSuggestedPorts()?.first, suggestedPorts.protocolType != "", suggestedPorts.port != "" {
                defaultProtocol = suggestedPorts.protocolType
                defaultPort = suggestedPorts.port
            }
            guard let autoSecureNewNetworks = try? self.selectedAutoSecureNewNetworks.value() else {return}
            let wifiNetwork = WifiNetwork(SSID: wifiSSID,
                                          status: !autoSecureNewNetworks,
                                          protocolType: defaultProtocol,
                                          port: defaultPort,
                                          preferredProtocol: defaultProtocol,
                                          preferredPort: defaultPort)

            if let results = try? self.wifiNetworks.value(), results.first?.isInvalidated == false {
                let SSIDs = results.map({ $0.SSID })
                if !SSIDs.contains(wifiNetwork.SSID) {
                    if "Unknown" != wifiNetwork.SSID {
                        VPNManager.shared.updateOnDemandRules()
                    }
                    self.logger.logD(self, "New Wi-fi added \(wifiNetwork.SSID)")
                    self.setSelectedNetworkSettings(wifiNetwork, existingNetwork: false, defaultProtocol: defaultProtocol, defaultPort: defaultPort)

                } else {
                    if let network = results.filter({ $0.SSID == wifiSSID}).first {
                        self.setSelectedNetworkSettings(network, existingNetwork: true, defaultProtocol: defaultProtocol, defaultPort: defaultPort)
                    }
                }
            } else {
                self.logger.logE(self, "Error when saving Wi-fi networks")
            }
        }
    }

    func saveCellularNetwork() {
        var defaultProtocol = TextsAsset.General.protocols[0]
        var defaultPort = localDb.getPorts(protocolType: defaultProtocol)?.first ?? "443"

        if let suggestedPorts = localDb.getSuggestedPorts()?.first, suggestedPorts.protocolType != "", suggestedPorts.port != "" {
            defaultProtocol = suggestedPorts.protocolType
            defaultPort = suggestedPorts.port
        }
        let cellularNetwork = WifiNetwork(SSID: TextsAsset.cellular,
                                          status: false,
                                          protocolType: defaultProtocol,
                                          port: defaultPort,
                                          preferredProtocol: defaultProtocol,
                                          preferredPort: defaultPort)
        if let results = try? wifiNetworks.value() {
            let SSIDs = results.filter {$0.isInvalidated == false}.map({ $0.SSID })
            if !SSIDs.contains(cellularNetwork.SSID) {
                self.logger.logD(self, "Cellular network added.")

                setSelectedNetworkSettings(cellularNetwork, existingNetwork: false, defaultProtocol: defaultProtocol, defaultPort: defaultPort)
            } else {
                if let network = results.filter({ $0.SSID == cellularNetwork.SSID}).first {
                    setSelectedNetworkSettings(network, existingNetwork: true, defaultProtocol: defaultProtocol, defaultPort: defaultPort)
                }
            }
        } else {
            self.logger.logD(self, "Error when saving cellular network")
        }
    }

    // added selected network settings to current WifiManager
    func setSelectedNetworkSettings(_ network: WifiNetwork, existingNetwork: Bool, defaultProtocol: String = "", defaultPort: String = "") {
        if existingNetwork {
            preferences.getConnectionMode().subscribe { data in
                self.connectionMode.onNext(data)
            }.disposed(by: disposeBag)
            guard let connectionMode = try? self.connectionMode.value() else {return}
            if connectionMode != Fields.Values.manual && network.preferredProtocolStatus == false {
                if network.protocolType != defaultProtocol {
                    localDb.updateWifiNetwork(network: network,
                                              properties: [
                                                Fields.protocolType: defaultProtocol,
                                                Fields.port: defaultPort
                                              ])
                    network.protocolType = defaultProtocol
                    network.port = defaultPort
                }
            }
            WifiManager.shared.selectedPreferredProtocolStatus =  network.preferredProtocolStatus
            WifiManager.shared.selectedPreferredProtocol = network.preferredProtocol
            WifiManager.shared.selectedPreferredPort = network.preferredPort
            WifiManager.shared.selectedProtocol = network.protocolType
            WifiManager.shared.selectedPort = network.port
        } else {
            // Added condition to not add unknown in networks list
            if network.SSID != "Unknown" {
                localDb.saveNetwork(wifiNetwork: network).disposed(by: disposeBag)
            }
            WifiManager.shared.selectedPreferredProtocolStatus = false
            WifiManager.shared.selectedProtocol = defaultProtocol
            WifiManager.shared.selectedPort = defaultPort
        }

    }

    func getConnectedWifiNetworkSSID() -> String? {
        return connectivity.getWifiSSID()
    }

    private func getNetworkName(completion: @escaping (String?) -> Void) {
        let networkType = connectivity.getNetwork().networkType
        if networkType == .cellular {
            completion(TextsAsset.cellular)
        }
        connectivity.getNetworkName(networkType: networkType, completion: completion)
    }

    func isConnectedWifiTrusted() -> Bool {
        let results = try? wifiNetworks.value()
        let SSIDs = results?.filter {$0.isInvalidated == false}.filter({ $0.status == true }).map({ $0.SSID })
        guard let connectedNetwork = getConnectedWifiNetworkSSID() else {
            return false
        }
        return SSIDs?.contains(connectedNetwork) ?? false
    }
}

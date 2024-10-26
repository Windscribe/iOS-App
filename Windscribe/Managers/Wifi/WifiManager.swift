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
import NetworkExtension
import Swinject
import RxSwift

class WifiManager {

    static let shared = WifiManager()
    lazy var preferences: Preferences = {
        return Assembler.resolve(Preferences.self)
    }()
    lazy var connectivity: Connectivity = {
        return Assembler.resolve(Connectivity.self)
    }()
    private lazy var localDb = Assembler.resolve(LocalDatabase.self)
    private lazy var logger = Assembler.resolve(FileLogger.self)

    private let disposeBag = DisposeBag()
    var selectedProtocol: String?
    var selectedPort: String?
    var selectedPreferredProtocol: String?
    var selectedPreferredPort: String?
    var selectedPreferredProtocolStatus: Bool?

    private var connectedSecuredNetwork: WifiNetwork?
    private var autoSecureNewNetworks = BehaviorSubject<Bool>(value: DefaultValues.autoSecureNewNetworks)
    private var connectionMode = BehaviorSubject<String>(value: DefaultValues.connectionMode)
    private var securedNetworks = BehaviorSubject<[WifiNetwork]>(value: [])
    private var observingNetworks = false
    private var initialNetworkFetch = true

    init() {
        observeSecuredNetworks()
        observeAutoSecureSettings()
        preferences.getConnectionMode().subscribe { data in
            self.connectionMode.onNext(data ?? DefaultValues.connectionMode)
        }.disposed(by: disposeBag)
        preferences.getAutoSecureNewNetworks().subscribe { data in
            self.autoSecureNewNetworks.onNext(data ?? DefaultValues.autoSecureNewNetworks)
        }.disposed(by: disposeBag)
    }

    func getConnectedNetwork() -> WifiNetwork? {
        return connectedSecuredNetwork
    }

    func isConnectedWifiTrusted() -> Bool {
        let results = try? securedNetworks.value()
        let SSIDs = results?.filter({ $0.status == true }).map({ $0.SSID })
        guard let connectedNetwork = connectivity.getWifiSSID() else {
            return false
        }
        return SSIDs?.contains(connectedNetwork) ?? false
    }

    func saveCurrentWifiNetworks() {
        _ = connectivity.network.take(1).map {$0.name}.subscribe(onNext: { wifiSSID in
            guard let wifiSSID = wifiSSID else {
                return
            }
            var defaultProtocol = TextsAsset.General.protocols[0]
            var defaultPort = self.localDb.getPorts(protocolType: defaultProtocol)?.first ?? "443"

            if let suggestedPorts = self.localDb.getSuggestedPorts()?.first, suggestedPorts.protocolType != "", suggestedPorts.port != "" {
                defaultProtocol = suggestedPorts.protocolType
                defaultPort = suggestedPorts.port
            }
            guard let autoSecureNewNetworks = try? self.autoSecureNewNetworks.value() else {return}
            let wifiNetwork = WifiNetwork(SSID: wifiSSID,
                                          status: !autoSecureNewNetworks,
                                          protocolType: defaultProtocol,
                                          port: defaultPort,
                                          preferredProtocol: defaultProtocol,
                                          preferredPort: defaultPort)

            let savedNetworks = self.localDb.getNetworksSync() ?? []
            let SSIDs = savedNetworks.map({ $0.SSID })
            if !SSIDs.contains(wifiNetwork.SSID) {
                if "Unknown" != wifiNetwork.SSID {
                    VPNManager.shared.updateOnDemandRules()
                }
                self.setSelectedNetworkSettings(wifiNetwork, existingNetwork: false, defaultProtocol: defaultProtocol, defaultPort: defaultPort)

            } else {
                if let network = savedNetworks.filter({ $0.SSID == wifiSSID}).first {
                    self.setSelectedNetworkSettings(network, existingNetwork: true, defaultProtocol: defaultProtocol, defaultPort: defaultPort)
                }
            }
        })
    }

    private func observeSecuredNetworks() {
        observingNetworks = true
        Observable.combineLatest(
            localDb.getNetworks(),
            connectivity.network.asObservable()
        ).subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] (networks, network) in
            self.securedNetworks.onNext(networks)
            guard !networks.isEmpty else {
                self.connectedSecuredNetwork = nil
                return
            }
            if self.initialNetworkFetch {
                self.setSelectedPreferences()
            } else {
                self.updateSelectedPreferences()
            }
            self.initialNetworkFetch = false
            self.connectedSecuredNetwork = networks.filter { $0.SSID == network.name }.first
            if self.connectedSecuredNetwork == nil {
                guard let networkName = network.name else { return }
                self.saveNewNetwork(wifiSSID: networkName)
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
        if let autoSecureNewNetworks = try? self.autoSecureNewNetworks.value() {
            let defaultProtocol = TextsAsset.General.protocols[0]
            let defaultPort = localDb.getPorts(protocolType: defaultProtocol)?.first ?? "443"
            let network = WifiNetwork(SSID: wifiSSID,
                                    status: !autoSecureNewNetworks,
                                    protocolType: defaultProtocol,
                                    port: defaultPort,
                                    preferredProtocol: defaultProtocol,
                                    preferredPort: defaultPort)
            logger.logD(self, "Adding \"\(wifiSSID)\" to \(network.status ? "Unsecured" : "secured") networks database.")
            localDb.saveNetwork(wifiNetwork: network).disposed(by: disposeBag)
            if !observingNetworks {
                observeSecuredNetworks()
            }
        }
    }

    private func setSelectedPreferences() {
        guard let result = getConnectedNetwork() else { return }
        self.selectedPreferredProtocol = result.preferredProtocol
        self.selectedPreferredPort = result.preferredPort
        self.selectedPreferredProtocolStatus = result.preferredProtocolStatus
    }

    private func updateSelectedPreferences() {
        guard let result = connectedSecuredNetwork else { return }
        if (result.protocolType != self.selectedProtocol) || (result.port != self.selectedPort) {
            self.logger.logI(self, "Protocol for \"\(result.SSID)\" is set to \(result.protocolType):\(result.port)")
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

    private func setSelectedNetworkSettings(_ network: WifiNetwork, existingNetwork: Bool, defaultProtocol: String = "", defaultPort: String = "") {
        if existingNetwork {
            selectedPreferredProtocolStatus =  network.preferredProtocolStatus
            selectedPreferredProtocol = network.preferredProtocol
            selectedPreferredPort = network.preferredPort
            selectedProtocol = network.protocolType
            selectedPort = network.port
            guard let connectionMode = try? self.connectionMode.value() else { return }
            if connectionMode != Fields.Values.manual && network.preferredProtocolStatus == false {
                if network.protocolType != defaultProtocol {
                    logger.logI(self, "Updating \"\(network.SSID)\"'s protocol settings to \(defaultProtocol):\(defaultPort)")
                    localDb.updateWifiNetwork(network: network,
                                              properties: [
                                                Fields.protocolType: defaultProtocol,
                                                Fields.port: defaultPort
                                              ])
                    selectedProtocol = defaultProtocol
                    selectedPort = defaultPort
                }
            }
        } else {
            if network.SSID != "Unknown" {
                localDb.saveNetwork(wifiNetwork: network).disposed(by: disposeBag)
            }
            selectedPreferredProtocolStatus = false
            selectedProtocol = defaultProtocol
            selectedPort = defaultPort
        }

    }
}

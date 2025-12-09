//
//  WifiManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import Combine
import Swinject
import SystemConfiguration.CaptiveNetwork

class WifiManager {
    static let shared = WifiManager()
    lazy var preferences: Preferences = Assembler.resolve(Preferences.self)

    lazy var connectivity: ConnectivityManager = Assembler.resolve(ConnectivityManager.self)

    private lazy var localDatabase = Assembler.resolve(LocalDatabase.self)
    private lazy var logger = Assembler.resolve(FileLogger.self)
    private lazy var vpnManager = Assembler.resolve(VPNManager.self)
    private let wifiNetworkRepository = Assembler.resolve(WifiNetworkRepository.self)

    var selectedProtocol: String?
    var selectedPort: String?
    var selectedPreferredProtocol: String?
    var selectedPreferredPort: String?
    var selectedPreferredProtocolStatus: Bool?

    private var connectedSecuredNetwork: WifiNetworkModel?
    private var autoSecureNewNetworks = CurrentValueSubject<Bool, Never>(DefaultValues.autoSecureNewNetworks)
    private var connectionMode = CurrentValueSubject<String, Never>(DefaultValues.connectionMode)
    private var securedNetworksStatus = CurrentValueSubject<[[String: Bool]], Never>([])
    private var observingNetworks = false
    private var initialNetworkFetch = true
    private var cancellables = Set<AnyCancellable>()

    init() {
        observeSecuredNetworks()

        preferences.getConnectionMode()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.connectionMode.send(data ?? DefaultValues.connectionMode)
            }
            .store(in: &cancellables)

        preferences.getAutoSecureNewNetworks()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] autoSecure in
                guard let self = self else { return }
                self.logger.logI("WifiManager", "Auto secure network setting: \(autoSecure)")
                self.autoSecureNewNetworks.send(autoSecure)
            }
            .store(in: &cancellables)
    }

    func getConnectedNetwork() -> WifiNetworkModel? {
        return connectedSecuredNetwork
    }

    func isConnectedWifiTrusted() -> Bool {
        guard let connectedNetwork = connectivity.getWifiSSID() else {
            return false
        }
        let trustedSSIDs = securedNetworksStatus.value.flatMap { $0.filter { $0.value }.keys }
        return trustedSSIDs.contains(connectedNetwork)
    }

    func saveCurrentWifiNetworks() {
        connectivity.network
            .prefix(1)
            .map { $0.name }
            .timeout(.seconds(5), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("WifiManager", "Unable to get network name, error: \(error)")
                }
            }, receiveValue: { [weak self] wifiSSID in
                guard let self = self,
                      let wifiSSID = wifiSSID else { return }

                var defaultProtocol = TextsAsset.General.protocols[0]
                var defaultPort = self.localDatabase.getPorts(protocolType: defaultProtocol)?.first ?? "443"

                if let suggestedPorts = self.localDatabase.getSuggestedPorts()?.first,
                   suggestedPorts.protocolType != "",
                   suggestedPorts.port != "" {
                    defaultProtocol = suggestedPorts.protocolType
                    defaultPort = suggestedPorts.port
                }

                let wifiNetwork = WifiNetworkModel(SSID: wifiSSID,
                                              status: !self.autoSecureNewNetworks.value,
                                              protocolType: defaultProtocol,
                                              port: defaultPort,
                                              preferredProtocol: defaultProtocol,
                                              preferredPort: defaultPort)
                let savedNetworks = self.wifiNetworkRepository.networks.value
                let SSIDs = savedNetworks.map { $0.SSID }
                if !SSIDs.contains(wifiNetwork.SSID) {
                    if wifiNetwork.SSID != "Unknown" {
                        self.vpnManager.updateOnDemandRules()
                    }
                    self.setSelectedNetworkSettings(wifiNetwork,
                                                    existingNetwork: false,
                                                    defaultProtocol: defaultProtocol,
                                                    defaultPort: defaultPort)
                } else {
                    if let network = savedNetworks.filter({ $0.SSID == wifiSSID }).first {
                        self.setSelectedNetworkSettings(WifiNetworkModel(from: network),
                                                        existingNetwork: true,
                                                        defaultProtocol: defaultProtocol,
                                                        defaultPort: defaultPort)
                    }
                }
            })
            .store(in: &cancellables)
    }

    private func observeSecuredNetworks() {
        observingNetworks = true
        Publishers.CombineLatest(wifiNetworkRepository.networks, connectivity.network.eraseToAnyPublisher())
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    self.logger.logE("WifiManager", "Error getting network list. \(error)")
                }
                self.observingNetworks = false
            }, receiveValue: { [weak self] (wifiNetworks, appNetwork) in
                guard let self = self else { return }
                let networkModels = wifiNetworks.map {WifiNetworkModel(from: $0)}
                self.securedNetworksStatus.send(networkModels.map { [$0.SSID: $0.status] })
                guard !networkModels.isEmpty else {
                    self.connectedSecuredNetwork = nil
                    return
                }
                if self.initialNetworkFetch {
                    self.setSelectedPreferences()
                } else {
                    self.updateSelectedPreferences()
                }
                self.initialNetworkFetch = false
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.connectedSecuredNetwork = networkModels.filter {
                        $0.SSID == appNetwork.name
                    }.first
                    if self.connectedSecuredNetwork == nil {
                        guard let networkName = appNetwork.name else { return }
                        self.saveNewNetwork(wifiSSID: networkName)
                    }
                }
            })
            .store(in: &cancellables)
    }

    private func saveNewNetwork(wifiSSID: String) {
        let defaultProtocol = TextsAsset.General.protocols[0]
        let defaultPort = localDatabase.getPorts(protocolType: defaultProtocol)?.first ?? "443"
        let status = !autoSecureNewNetworks.value
        logger.logI("WifiManager", "Adding \"\(wifiSSID)\" to \(status ? "Unsecured" : "secured") networks database.")
        wifiNetworkRepository.addNetwork(wifiSSID: wifiSSID,
                                         status: status,
                                         protocolType: defaultProtocol,
                                         port: defaultPort,
                                         preferredProtocol: defaultProtocol,
                                         preferredPort: defaultPort)
        if !observingNetworks {
            observeSecuredNetworks()
        }
    }

    private func setSelectedPreferences() {
        guard let result = getConnectedNetwork() else { return }
        selectedPreferredProtocol = result.preferredProtocol
        selectedPreferredPort = result.preferredPort
        selectedPreferredProtocolStatus = result.preferredProtocolStatus
    }

    private func updateSelectedPreferences() {
        guard let result = connectedSecuredNetwork else { return }
        if (result.protocolType != selectedProtocol) || (result.port != selectedPort) {
            logger.logI("WifiManager", "Protocol for \"\(result.SSID)\" is set to \(result.protocolType):\(result.port)")
            selectedProtocol = result.protocolType
            selectedPort = result.port
        }
        if selectedPreferredProtocol != result.preferredProtocol {
            selectedPreferredProtocol = result.preferredProtocol
        }
        if selectedPreferredPort != result.preferredPort {
            selectedPreferredPort = result.preferredPort
        }
        if selectedPreferredProtocolStatus != result.preferredProtocolStatus {
            selectedPreferredProtocolStatus = result.preferredProtocolStatus
            if result.preferredProtocolStatus == true {
                selectedPreferredProtocol = result.preferredProtocol
                selectedPreferredPort = result.preferredPort
            }
        }
    }

    private func setSelectedNetworkSettings(_ network: WifiNetworkModel, existingNetwork: Bool, defaultProtocol: String = "", defaultPort: String = "") {
        if existingNetwork {
            selectedPreferredProtocolStatus = network.preferredProtocolStatus
            selectedPreferredProtocol = network.preferredProtocol
            selectedPreferredPort = network.preferredPort
            selectedProtocol = network.protocolType
            selectedPort = network.port

            if connectionMode.value != Fields.Values.manual, network.preferredProtocolStatus == false {
                if network.protocolType != defaultProtocol {
                    logger.logI("WifiManager", "Updating \"\(network.SSID)\"'s protocol settings to \(defaultProtocol):\(defaultPort)")
                    wifiNetworkRepository.updateNetworkProtocolAndPort(network: network, protocol: defaultProtocol, port: defaultPort)
                    selectedProtocol = defaultProtocol
                    selectedPort = defaultPort
                }
            }
        } else {
            if network.SSID != "Unknown" {
                wifiNetworkRepository.touchNetwork(network: network)
            }
            selectedPreferredProtocolStatus = false
            selectedProtocol = defaultProtocol
            selectedPort = defaultPort
        }
    }
}

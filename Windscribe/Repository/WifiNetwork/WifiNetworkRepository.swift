//
//  WifiNetworkRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-10.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol WifiNetworkRepository {
    var networks: CurrentValueSubject<[WifiNetworkModel], Never> { get }
    func addNetwork(status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String)
    func addNetwork(wifiSSID: String, status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String)
    func getCurrentNetwork() -> WifiNetworkModel?
    func getOtherNetworks() -> [WifiNetworkModel]?
    func removeNetwork(network: WifiNetworkModel)
    func setNetworkPreferredProtocol(network: WifiNetworkModel, status: Bool)
    func setNetworkDontAskAgainForPreferredProtocol(network: WifiNetworkModel)
    func incrementNetworkDismissCount(network: WifiNetworkModel)
    func updateNetworkPreferredProtocol(with preferredProtocol: String, andPort port: String)
    func updateNetworkPreferredProtocol(network: WifiNetworkModel, protocol: String, port: String)
    func updateNetworkPreferredProtocolStatus(network: WifiNetworkModel, status: Bool)
    func updateNetworkTrustStatus(network: WifiNetworkModel, trusted: Bool)
    func updateNetworkProtocolAndPort(network: WifiNetworkModel, protocol: String, port: String)
    func updateNetworkPreferredPort(network: WifiNetworkModel, port: String)
    func updateNetworkPreferredProtocolWithStatus(network: WifiNetworkModel, protocol: String, port: String, status: Bool)
    func touchNetwork(network: WifiNetworkModel)
}

/// Manages Auto secure networks  data
class WifiNetworkRepositoryImpl: WifiNetworkRepository {
    private let preferences: Preferences
    private let localDatabase: LocalDatabase
    private let connectivity: ConnectivityManager
    private let logger: FileLogger

    private var isObserving = false
    private var cancellables = Set<AnyCancellable>()
    let networks = CurrentValueSubject<[WifiNetworkModel], Never>([])

    init(preferences: Preferences, localDatabase: LocalDatabase, connectivity: ConnectivityManager, logger: FileLogger) {
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.connectivity = connectivity
        self.logger = logger
        loadNetworks()
    }

    /// Observers and Loads saved networks from data base
    private func loadNetworks() {
        isObserving = true
        localDatabase.getNetworks()
            .toPublisherIncludingEmpty()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    if case .failure(let error) = completion {
                        self.logger.logD("WifiNetworkRepository", "Error getting networks: \(error)")
                        self.networks.send([])
                    } else {
                        self.logger.logD("WifiNetworkRepository", "getNetworks onCompleted")
                        self.isObserving = false
                    }
                },
                receiveValue: { [weak self] savedNetworks in
                    guard let self = self else { return }
                    self.logger.logD("WifiNetworkRepository", "Secured Networks : \(savedNetworks)")
                    self.networks.send(savedNetworks.map { WifiNetworkModel(from: $0) })
                })
            .store(in: &cancellables)
    }

    /// Returns currently connected saved network if avaialble
    func getCurrentNetwork() -> WifiNetworkModel? {
        self.logger.logD("WifiNetworkRepository", "connectivity.getNetwork() \(connectivity.getNetwork())")
        let networkName = connectivity.getNetwork().name
        return networks.value.first { networkName == $0.SSID }
    }

    /// Returns all saved network excluding current network.
    func getOtherNetworks() -> [WifiNetworkModel]? {
        let networkName = connectivity.getNetwork().name
        return networks.value.filter { networkName != $0.SSID }
    }

    /// Adds current network with given settings to database if network name is avaialble.
    func addNetwork(status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String) {
        if let networkName = connectivity.getNetwork().name {
            addNetwork(wifiSSID: networkName,
                       status: status,
                       protocolType: protocolType,
                       port: port,
                       preferredProtocol: preferredProtocol,
                       preferredPort: preferredPort)
        }
    }
    func addNetwork(wifiSSID: String, status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String) {
        localDatabase.saveNetwork(wifiNetwork: WifiNetwork(SSID: wifiSSID,
                                                           status: status,
                                                           protocolType: protocolType,
                                                           port: port,
                                                           preferredProtocol: preferredProtocol,
                                                           preferredPort: preferredPort))
        // if this is the first object being added to database, add observer again.
        if !isObserving {
            loadNetworks()
        }
    }

    /// Remove network from database.
    func removeNetwork(network: WifiNetworkModel) {
        localDatabase.removeNetwork(wifiNetwork: WifiNetwork(from: network))
    }

    func setNetworkPreferredProtocol(network: WifiNetworkModel, status: Bool) {
        updateWifiNetwork(from: network, with: [.preferredProtocolStatus(value: status)])
    }

    func updateNetworkPreferredProtocol(with preferredProtocol: String, andPort port: String) {
        if let network = getCurrentNetwork() {
            localDatabase.saveNetwork(wifiNetwork: WifiNetwork(from: network))
            updateWifiNetwork(from: network, with: [.preferredProtocol(value: preferredProtocol),
                                                    .preferredPort(value: port)])
        }
    }

    func setNetworkDontAskAgainForPreferredProtocol(network: WifiNetworkModel) {
        updateWifiNetwork(from: network, with: [.dontAskAgainForPreferredProtocol(value: true)])
    }

    func incrementNetworkDismissCount(network: WifiNetworkModel) {
        updateWifiNetwork(from: network, with: [.popupDismissCount(value: network.popupDismissCount + 1)])
    }

    func updateNetworkPreferredProtocol(network: WifiNetworkModel, protocol: String, port: String) {
        updateWifiNetwork(from: network, with: [.preferredProtocol(value: `protocol`), .preferredPort(value: port)])
    }

    func updateNetworkPreferredProtocolStatus(network: WifiNetworkModel, status: Bool) {
        updateWifiNetwork(from: network, with: [.preferredProtocolStatus(value: status)])
    }

    func updateNetworkTrustStatus(network: WifiNetworkModel, trusted: Bool) {
        updateWifiNetwork(from: network, with: [.preferredProtocolStatus(value: false), .status(value: !trusted)])
    }

    func updateNetworkProtocolAndPort(network: WifiNetworkModel, protocol: String, port: String) {
        updateWifiNetwork(from: network, with: [.protocolType(value: `protocol`), .port(value: port)])
    }

    func updateNetworkPreferredPort(network: WifiNetworkModel, port: String) {
        updateWifiNetwork(from: network, with: [.preferredPort(value: port)])
    }

    func updateNetworkPreferredProtocolWithStatus(network: WifiNetworkModel, protocol: String, port: String, status: Bool) {
        updateWifiNetwork(from: network, with: [.preferredProtocol(value: `protocol`), .preferredPort(value: port), .preferredProtocolStatus(value: status)])
    }

    func touchNetwork(network: WifiNetworkModel) {
        updateWifiNetwork(from: network, with: [])
    }

    private func updateWifiNetwork(from network: WifiNetworkModel, with properties: [WifiNetworkValues]) {
        var updatedNetwork = network
        for (property) in properties {
            switch property {
            case .status(let value):
                updatedNetwork.status = value
            case .preferredPort(let value):
                updatedNetwork.preferredPort = value
            case .preferredProtocol(let value):
                updatedNetwork.preferredProtocol = value
            case .preferredProtocolStatus(let value):
                updatedNetwork.preferredProtocolStatus = value
            case .dontAskAgainForPreferredProtocol(let value):
                updatedNetwork.dontAskAgainForPreferredProtocol = value
            case .protocolType(let value):
                updatedNetwork.protocolType = value
            case .port(let value):
                updatedNetwork.port = value
            case .popupDismissCount(let value):
                updatedNetwork.popupDismissCount = value
            }
        }
        localDatabase.saveNetwork(wifiNetwork: WifiNetwork(from: updatedNetwork))
    }
}

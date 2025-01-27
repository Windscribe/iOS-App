//
//  SecuredNetworkRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-10.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

/// Manages Auto secure networks  data
class SecuredNetworkRepositoryImpl: SecuredNetworkRepository {
    private let preferences: Preferences
    private let localdatabase: LocalDatabase
    private let connectivity: Connectivity
    private let logger: FileLogger

    private var isObserving = false
    private let disposeBag = DisposeBag()
    let networks: BehaviorSubject<[WifiNetwork]> = BehaviorSubject(value: [])

    init(preferences: Preferences, localdatabase: LocalDatabase, connectivity: Connectivity, logger: FileLogger) {
        self.preferences = preferences
        self.localdatabase = localdatabase
        self.connectivity = connectivity
        self.logger = logger
        loadNetworks()
    }

    /// Observers and Loads saved networks from data base
    private func loadNetworks() {
        isObserving = true
        localdatabase.getNetworks().subscribe(
            onNext: { savedNetworks in
                self.networks.onNext(savedNetworks)
            }, onError: { _ in
                self.networks.onNext([])
            }, onCompleted: {
                self.isObserving = false
            }
        ).disposed(by: disposeBag)
    }

    /// Returns currently connected saved network if avaialble
    func getCurrentNetwork() -> WifiNetwork? {
        let networkName = connectivity.getNetwork().name
        return try? networks.value().first { networkName == $0.SSID }
    }

    /// Returns all saved network excluding current network.
    func getOtherNetworks() -> [WifiNetwork]? {
        let networkName = connectivity.getNetwork().name
        return try? networks.value().filter { networkName != $0.SSID }
    }

    /// Adds current network with given settings to database if network name is avaialble.
    func addNetwork(status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String) {
        if let networkName = connectivity.getNetwork().name {
            let updated = WifiNetwork(SSID: networkName, status: status, protocolType: protocolType, port: port, preferredProtocol: preferredProtocol, preferredPort: preferredPort)
            localdatabase.saveNetwork(wifiNetwork: updated)
                .disposed(by: disposeBag)
            // if this is the first object being added to database, add observer again.
            if !isObserving {
                loadNetworks()
            }
        }
    }

    /// Remove network from database.
    func removeNetwork(network: WifiNetwork) {
        localdatabase.removeNetwork(wifiNetwork: network)
    }

    func setNetworkPreferredProtocol(network: WifiNetwork) {
        localdatabase.updateNetworkWithPreferredProtocolSwitch(network: network, status: true)
    }

    func updateNetworkPreferredProtocol(with preferredProtocol: String, andPort port: String) {
        if let network = getCurrentNetwork() {
            localdatabase.updateWifiNetwork(network: network,
                                            properties: [Fields.WifiNetwork.preferredProtocol: preferredProtocol,
                                                         Fields.WifiNetwork.preferredPort: port])
        }
    }

    func setNetworkDontAskAgainForPreferredProtocol(network: WifiNetwork) {
        localdatabase.updateNetworkDontAskAgainForPreferredProtocol(network: network, status: true)
    }

    func incrementNetworkDismissCount(network: WifiNetwork) {
        localdatabase.updateNetworkDismissCount(network: network, dismissCount: network.popupDismissCount + 1)
    }
}

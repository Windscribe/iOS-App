//
//  NetworkViewModel.swift
//  Windscribe
//
//  Created by Thomas on 11/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

typealias CompletionHandler = () -> Void

protocol NetworkOptionViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    var networks: BehaviorSubject<[WifiNetwork]> { get set }
    var lookAndFeelRepo: LookAndFeelRepositoryType { get set }
    var displayingNetwork: WifiNetwork? { get set }
    var preferredProtocol: String? { get set }
    var preferredPort: String? { get set }
    var hideForgetNetwork: Bool { get set }

    var trustNetworkStatus: Bool { get set }
    var preferredProtocolStatus: Bool { get set }
    var showPreferredProtocol: Bool { get set }

    func updatePreferredProtocol(value: String)
    func toggleAutoSecure()
    func updatePreferredPort(value: String)
    func getPorts(by protocolType: String) -> [String]
    func getProtocols() -> [String]
    func getDefaultPorts() -> [String]
    func updatePreferredProtocolSwitch(_ status: Bool, completion: CompletionHandler)
    func updateTrustNetwork(_ status: Bool, completion: CompletionHandler)
    func forgetNetwork(completion: CompletionHandler)
    func loadNetwork(completion: CompletionHandler)
}

class NetworkOptionViewModel: NetworkOptionViewModelType {
    var displayingNetwork: WifiNetwork?
    var preferredProtocol: String?
    var preferredPort: String?
    var hideForgetNetwork: Bool = false

    // auto-secure: true -> show, false -> hide
    var trustNetworkStatus: Bool = false
    var preferredProtocolStatus: Bool = false
    var showPreferredProtocol: Bool = false
    var networks: BehaviorSubject<[WifiNetwork]> = BehaviorSubject(value: [])
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)

    private let localDatabase: LocalDatabase
    private let connectivity: Connectivity
    private let vpnManager: VPNManager
    let protocolManager: ProtocolManagerType
    var lookAndFeelRepo: LookAndFeelRepositoryType
    private let disposeBag = DisposeBag()

    init(localDatabase: LocalDatabase,
         lookAndFeelRepo: LookAndFeelRepositoryType,
         connectivity: Connectivity,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType) {
        self.localDatabase = localDatabase
        self.lookAndFeelRepo = lookAndFeelRepo
        self.connectivity = connectivity
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        loadData()
    }

    private func loadData() {
        localDatabase.getNetworks().filter { $0.filter { $0.isInvalidated }.count == 0 }.subscribe { networks in
            self.networks.onNext(networks)
        }.disposed(by: disposeBag)

        lookAndFeelRepo.isDarkModeSubject.subscribe { data in
            self.isDarkMode.onNext(data)
        }.disposed(by: disposeBag)
    }

    func loadNetwork(completion: CompletionHandler) {
        let existingNetworks = (try? networks.value().filter { !$0.isInvalidated }) ?? []
        if displayingNetwork?.isInvalidated == true {
            completion()
            return
        }
        guard let networkSSID = displayingNetwork?.SSID, let network = existingNetworks
            .filter({ $0.SSID == networkSSID })
            .first else { return }

        preferredProtocol = network.preferredProtocol
        preferredPort = network.preferredPort

        trustNetworkStatus = !network.status

        preferredProtocolStatus = network.preferredProtocolStatus
        if network.preferredProtocolStatus == true && network.status == false {
            showPreferredProtocol = true
        } else {
            showPreferredProtocol = false
        }
        if connectivity.getWifiSSID() == displayingNetwork?.SSID {
            hideForgetNetwork = true
        }
        completion()
    }

    func toggleAutoSecure() {
        trustNetworkStatus.toggle()
    }

    func updatePreferredProtocol(value: String) {
        guard let network = displayingNetwork else { return }
        let port = getPorts(by: value).first ?? DefaultValues.port
        let updated = WifiNetwork(SSID: network.SSID, status: network.status, protocolType: network.protocolType, port: network.port, preferredProtocol: value, preferredPort: port, preferredProtocolStatus: network.preferredProtocolStatus)
        localDatabase.saveNetwork(wifiNetwork: updated).disposed(by: disposeBag)
        preferredProtocol = network.preferredProtocol
        Task {
            await protocolManager.refreshProtocols(shouldReset: true,
                                                   shouldReconnect: vpnManager.isConnected())
        }
    }

    func updatePreferredPort(value: String) {
        guard let network = displayingNetwork else { return }
        let updated = WifiNetwork(SSID: network.SSID, status: network.status, protocolType: network.protocolType, port: network.port, preferredProtocol: network.preferredProtocol, preferredPort: value, preferredProtocolStatus: network.preferredProtocolStatus)
        localDatabase.saveNetwork(wifiNetwork: updated).disposed(by: disposeBag)
        preferredPort = network.preferredPort
    }

    func getPorts(by protocolType: String) -> [String] {
        guard let portsArray = localDatabase.getPorts(protocolType: protocolType) else { return [] }
        return portsArray
    }

    func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    func getDefaultPorts() -> [String] {
        if let preferredProtocol = preferredProtocol {
            return getPorts(by: preferredProtocol)
        } else {
            return []
        }
    }

    func updatePreferredProtocolSwitch(_ status: Bool, completion: CompletionHandler) {
        guard let network = displayingNetwork else { return }
        if network.status == true { return }

        localDatabase.updateNetworkWithPreferredProtocolSwitch(network: network, status: status)
        loadNetwork(completion: completion)
    }

    // Auto-secure
    func updateTrustNetwork(_ status: Bool, completion: CompletionHandler) {
        guard let network = displayingNetwork else { return }
        localDatabase.updateTrustNetwork(network: network, status: status)
        vpnManager.updateOnDemandRules()
        loadNetwork(completion: completion)
    }

    func forgetNetwork(completion: CompletionHandler) {
        guard let network = displayingNetwork else { return }
        localDatabase.removeNetwork(wifiNetwork: network)
        completion()
    }
}

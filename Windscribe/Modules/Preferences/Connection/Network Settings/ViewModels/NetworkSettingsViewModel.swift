//
//  NetworkSettingsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 29/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import RxSwift

protocol NetworkSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var shouldDismiss: Bool { get }
    var entries: [NetworkSettingsEntryTpe] { get }

    func entrySelected(_ entry: NetworkSettingsEntryTpe, action: MenuEntryActionResponseType)
    func updateDisplayingNetworks(with network: WifiNetwork)
}

class NetworkSettingsViewModelImpl: NetworkSettingsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var entries: [NetworkSettingsEntryTpe] = []

    private var cancellables = Set<AnyCancellable>()
    private var displayingNetwork: WifiNetwork?
    private var preferredProtocol: String?
    private var preferredPort: String?

    // MARK: - Dependencies
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let connectivity: Connectivity
    private let localDatabase: LocalDatabase
    private let vpnManager: VPNManager
    private let protocolManager: ProtocolManagerType

    private let disposeBag = DisposeBag()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         connectivity: Connectivity,
         localDatabase: LocalDatabase,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.connectivity = connectivity
        self.localDatabase = localDatabase
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager

        bindSubjects()
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("NetworkOptionsSecurityViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
                self?.reloadItems()
            })
            .store(in: &cancellables)

        localDatabase.getNetworks()
            .toPublisher(initialValue: [])
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("NetworkOptionsSecurityViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] networks in
                guard let self = self else { return }
                guard !(self.displayingNetwork?.isInvalidated ?? true) else { return }
                let network = networks
                    .filter { !$0.isInvalidated }
                    .first { $0.SSID == self.displayingNetwork?.SSID }
                guard let network = network else { return }
                self.displayingNetwork = network
                self.reloadItems()
            })
            .store(in: &cancellables)

    }

    private func reloadItems() {
        guard let network = displayingNetwork else { return }

        entries = [.autoSecure(isSelected: !network.status),
                   .preferredProtocol(isSelected: network.preferredProtocolStatus == true && network.status == false,
                                      protocolSelected: network.preferredProtocol,
                                      protocolOptions: getProtocols(),
                                      portSelected: network.preferredPort,
                                      portOptions: getPorts(by: network.preferredProtocol))]
        if connectivity.getWifiSSID() != displayingNetwork?.SSID {
            entries.append(.forget)
        }
    }

    func updateDisplayingNetworks(with network: WifiNetwork) {
        displayingNetwork = network
        reloadItems()
    }

    func entrySelected(_ entry: NetworkSettingsEntryTpe, action: MenuEntryActionResponseType) {
        switch entry {
        case .autoSecure:
            if case .toggle(let isSelected, _) = action {
                updateTrustNetwork(isSelected)
            }
        case .preferredProtocol:
            if case .toggle(let isSelected, _) = action {
                updatePreferredProtocolSwitch(isSelected)
            } else if case .multiple(let newOption, let parentId) = action {
                if parentId == NetworkSettingsSecondaryIDs.protocolMenu.id {
                    updatePreferredProtocol(value: newOption)
                } else if parentId == NetworkSettingsSecondaryIDs.portMenu.id {
                    updatePreferredPort(value: newOption)
                }
            }
        case .forget:
            forgetNetwork()
        }
    }

    private func updatePreferredProtocolSwitch(_ status: Bool) {
        guard let network = displayingNetwork else { return }
        if network.status == true { return }
        localDatabase.updateNetworkWithPreferredProtocolSwitch(network: network, status: status)
    }

    private func updatePreferredProtocol(value: String) {
        guard let network = displayingNetwork else { return }
        let port = getPorts(by: value).first ?? DefaultValues.port
        let updated = WifiNetwork(SSID: network.SSID, status: network.status, protocolType: network.protocolType, port: network.port, preferredProtocol: value, preferredPort: port, preferredProtocolStatus: network.preferredProtocolStatus)
        localDatabase.saveNetwork(wifiNetwork: updated).disposed(by: disposeBag)
        Task {
            await protocolManager.refreshProtocols(shouldReset: true,
                                                   shouldReconnect: vpnManager.isConnected())
        }
    }

    private func updatePreferredPort(value: String) {
        guard let network = displayingNetwork else { return }
        let updated = WifiNetwork(SSID: network.SSID, status: network.status, protocolType: network.protocolType, port: network.port, preferredProtocol: network.preferredProtocol, preferredPort: value, preferredProtocolStatus: network.preferredProtocolStatus)
        localDatabase.saveNetwork(wifiNetwork: updated).disposed(by: disposeBag)
        reloadItems()
    }

    private func getPorts(by protocolType: String) -> [String] {
        guard let portsArray = localDatabase.getPorts(protocolType: protocolType) else { return [] }
        return portsArray
    }

    private func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    private func updateTrustNetwork(_ status: Bool) {
        guard let network = displayingNetwork else { return }
        localDatabase.updateTrustNetwork(network: network, status: status)
        vpnManager.updateOnDemandRules()
        reloadItems()
    }

    private func forgetNetwork() {
        guard let network = displayingNetwork else { return }
        localDatabase.removeNetwork(wifiNetwork: network)
        shouldDismiss = true
    }
}

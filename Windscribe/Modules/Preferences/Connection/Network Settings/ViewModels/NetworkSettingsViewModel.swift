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

protocol NetworkSettingsViewModel: PreferencesBaseViewModel {
    var shouldDismiss: Bool { get }
    var entries: [NetworkSettingsEntryTpe] { get }

    func entrySelected(_ entry: NetworkSettingsEntryTpe, action: MenuEntryActionResponseType)
    func updateDisplayingNetworks(with network: WifiNetworkModel)
}

class NetworkSettingsViewModelImpl: PreferencesBaseViewModelImpl, NetworkSettingsViewModel {
    @Published var shouldDismiss: Bool = false
    @Published var entries: [NetworkSettingsEntryTpe] = []

    private var displayingNetwork: WifiNetworkModel?
    private var preferredProtocol: String?
    private var preferredPort: String?

    // MARK: - Dependencies
    private let connectivity: ConnectivityManager
    private let localDatabase: LocalDatabase
    private let vpnManager: VPNManager
    private let vpnStateRepository: VPNStateRepository
    private let protocolManager: ProtocolManagerType
    private let wifiNetworkRepository: WifiNetworkRepository

    private let disposeBag = DisposeBag()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         connectivity: ConnectivityManager,
         localDatabase: LocalDatabase,
         vpnManager: VPNManager,
         vpnStateRepository: VPNStateRepository,
         protocolManager: ProtocolManagerType,
         wifiNetworkRepository: WifiNetworkRepository) {
        self.connectivity = connectivity
        self.localDatabase = localDatabase
        self.vpnManager = vpnManager
        self.vpnStateRepository = vpnStateRepository
        self.protocolManager = protocolManager
        self.wifiNetworkRepository = wifiNetworkRepository

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        wifiNetworkRepository.networks
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("NetworkOptionsSecurityViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] wifiNetworks in
                guard let self = self else { return }
                let mappedNetwork = wifiNetworks
                    .first { $0.SSID == self.displayingNetwork?.SSID }
                guard let mappedNetwork = mappedNetwork else { return }
                self.displayingNetwork = mappedNetwork
                self.reloadItems()
            })
            .store(in: &cancellables)

    }

    override func reloadItems() {
        guard let network = displayingNetwork else { return }
        let protocolOptions = getProtocols()
            .map { MenuOption(title: $0, fieldKey: $0) }
        let portOptions = getPorts(by: network.preferredProtocol)
            .map { MenuOption(title: $0, fieldKey: $0) }

        entries = [.autoSecure(isSelected: !network.status),
                   .preferredProtocol(isSelected: network.preferredProtocolStatus == true && network.status == false,
                                      protocolSelected: network.preferredProtocol,
                                      protocolOptions: protocolOptions,
                                      portSelected: network.preferredPort,
                                      portOptions: portOptions)]
        if connectivity.getWifiSSID() != displayingNetwork?.SSID {
            entries.append(.forget)
        }
    }

    func updateDisplayingNetworks(with network: WifiNetworkModel) {
        displayingNetwork = network
        reloadItems()
    }

    func entrySelected(_ entry: NetworkSettingsEntryTpe, action: MenuEntryActionResponseType) {
        actionSelected(action)

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
        wifiNetworkRepository.updateNetworkPreferredProtocolStatus(network: network, status: status)
    }

    private func updatePreferredProtocol(value: String) {
        guard let network = displayingNetwork else { return }
        let port = getPorts(by: value).first ?? DefaultValues.port
        wifiNetworkRepository.updateNetworkPreferredProtocol(network: network, protocol: value, port: port)
        Task {
            self.logger.logI("NetworkSettingsViewModel", "updatePreferredProtocol for getNextProtocol")
            await protocolManager.refreshProtocols(shouldReset: true,
                                                   shouldReconnect: vpnStateRepository.isConnected())
        }
    }

    private func updatePreferredPort(value: String) {
        guard let network = displayingNetwork else { return }
        wifiNetworkRepository.updateNetworkPreferredPort(network: network, port: value)
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
        wifiNetworkRepository.updateNetworkTrustStatus(network: network, trusted: status)
        vpnManager.updateOnDemandRules()
        reloadItems()
    }

    private func forgetNetwork() {
        guard let network = displayingNetwork else { return }
        wifiNetworkRepository.removeNetwork(network: network)
        shouldDismiss = true
    }
}

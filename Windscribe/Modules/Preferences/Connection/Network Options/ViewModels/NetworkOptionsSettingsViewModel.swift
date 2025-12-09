//
//  NetworkOptionsSettingsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UserNotifications
import UIKit

protocol NetworkOptionsSecurityViewModel: PreferencesBaseViewModel {
    var autoSecureEntry: NetworkOptionsEntryType? { get set }
    var currentNetworkEntry: NetworkOptionsEntryType? { get set }
    var networkListEntry: NetworkOptionsEntryType? { get set }
    var router: ConnectionsNavigationRouter { get }

    func entrySelected(_ entry: NetworkOptionsEntryType, action: MenuEntryActionResponseType)
    func loadEntries()
}

class NetworkOptionsSecurityViewModelImpl: PreferencesBaseViewModelImpl, NetworkOptionsSecurityViewModel {
    @Published var autoSecureEntry: NetworkOptionsEntryType?
    @Published var currentNetworkEntry: NetworkOptionsEntryType?
    @Published var networkListEntry: NetworkOptionsEntryType?
    @Published var router: ConnectionsNavigationRouter

    private var networks: [WifiNetworkModel] = []
    private var currentNetwork: AppNetwork?
    private var isAutoSecureEnabled = DefaultValues.autoSecure
    private var hasLoaded = false

    // MARK: - Dependencies
    private let preferences: Preferences
    private let connectivity: ConnectivityManager
    private let wifiNetworkRepository: WifiNetworkRepository

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         connectivity: ConnectivityManager,
         router: ConnectionsNavigationRouter,
         wifiNetworkRepository: WifiNetworkRepository) {
        self.preferences = preferences
        self.connectivity = connectivity
        self.router = router
        self.wifiNetworkRepository = wifiNetworkRepository

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        preferences.getAutoSecureNewNetworks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                self.isAutoSecureEnabled = enabled ?? DefaultValues.autoSecure
                self.reloadItems()
            }
            .store(in: &cancellables)

        connectivity.network
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("NetworkOptionsSecurityViewModel", "Current Network error: \(error)")
                }
            }, receiveValue: { [weak self] network in
                guard let self = self else { return }
                self.currentNetwork = network
                self.reloadItems()
            })
            .store(in: &cancellables)

        wifiNetworkRepository.networks
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("NetworkOptionsSecurityViewModel", "Getting Networks error: \(error)")
                }
            }, receiveValue: { [weak self] wifiNetworks in
                guard let self = self else { return }
                self.networks = wifiNetworks
                self.reloadItems()
            })
            .store(in: &cancellables)
    }

    override func reloadItems() {
        autoSecureEntry = .autoSecure(isSelected: isAutoSecureEnabled)
        if let network = getCurrentWifiNetwork() {
            currentNetworkEntry = .network(info: NetworkEntryInfo(name: network.SSID, isSecured: !network.status))
        } else {
            currentNetworkEntry = nil
        }

        if networks.count > 0 {
            var mappedNetworks = networks
                .filter { currentNetwork?.name != $0.SSID }
                .map { NetworkEntryInfo(name: $0.SSID, isSecured: !$0.status) }
            if mappedNetworks.count >= 1 {
                let firstInfo = mappedNetworks.removeFirst()
                networkListEntry = .networkList(info: firstInfo, otherNetworks: mappedNetworks)
            } else {
                networkListEntry = nil
            }
        } else {
            networkListEntry = nil
        }
        hasLoaded = true
    }

    func loadEntries() {
        guard !hasLoaded else { return }
        reloadItems()
    }

    private func getCurrentWifiNetwork() -> WifiNetworkModel? {
        guard let currentSSID = currentNetwork?.name else { return nil }
        return networks.first { $0.SSID == currentSSID }
    }

    func entrySelected(_ entry: NetworkOptionsEntryType, action: MenuEntryActionResponseType) {
        actionSelected(action)

        switch entry {
        case .autoSecure:
            if case .toggle(let isSelected, _) = action {
                preferences.saveAutoSecureNewNetworks(autoSecure: isSelected)
            }
        case let .network(info):
            navigateToNetwork(named: info.name)
        case let .networkList(info, otherNetworks):
            if case .button(let parentId) = action {
                if entry.id == parentId {
                    navigateToNetwork(named: info.name)
                } else {
                    let index = parentId / 10
                    if index < networks.count {
                        navigateToNetwork(named: otherNetworks[index].name)
                    }
                }
            }
        }
    }

    private func navigateToNetwork(named: String) {
        if let network = networks.first(where: { $0.SSID == named }) {
            router.navigate(to: .networkSettings(network: network))
        }
    }
}

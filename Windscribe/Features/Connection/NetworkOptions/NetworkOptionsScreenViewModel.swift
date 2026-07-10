//
//  NetworkOptionsScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Routes for NetworkOptions screen navigation.
enum NetworkOptionsRoute: Hashable {
    case networkSettings(network: WifiNetworkModel)
}

@available(iOS 17.0, *)
@Observable
@MainActor
final class NetworkOptionsScreenViewModel {

    // MARK: - Private State
    private var isObserving = false
    private var networks: [WifiNetworkModel] = []
    private var currentNetwork: AppNetwork?
    private var isAutoSecureEnabled = DefaultValues.autoSecure

    // MARK: - Dependencies
    private let preferencesReading: any PreferencesReading
    private let preferencesWriting: any PreferencesWriting
    private let wifiNetworkProviding: any WifiNetworkProviding
    private let connectivityObserving: any ConnectivityObserving
    private let logger: any LogStoring

    // MARK: - Published State
    var navigationRoute: NetworkOptionsRoute? {
        didSet {
            isNavigating = navigationRoute != nil
        }
    }
    var isNavigating: Bool = false
    var safariURL: URL?
    var showingSafari: Bool = false

    // MARK: - Entries
    var autoSecureEntry: NetworkOptionsEntryType? {
        .autoSecure(isSelected: isAutoSecureEnabled)
    }

    var currentNetworkEntry: NetworkOptionsEntryType? {
        guard let network = getCurrentWifiNetwork() else { return nil }
        return .network(info: NetworkEntryInfo(name: network.SSID, isSecured: !network.status))
    }

    var networkListEntry: NetworkOptionsEntryType? {
        guard networks.count > 0 else { return nil }

        var mappedNetworks = networks
            .filter { currentNetwork?.name != $0.SSID }
            .map { NetworkEntryInfo(name: $0.SSID, isSecured: !$0.status) }

        guard mappedNetworks.count >= 1 else { return nil }

        let firstInfo = mappedNetworks.removeFirst()
        return .networkList(info: firstInfo, otherNetworks: mappedNetworks)
    }

    // MARK: - Initialization
    init(
        preferencesReading: any PreferencesReading,
        preferencesWriting: any PreferencesWriting,
        wifiNetworkProviding: any WifiNetworkProviding,
        connectivityObserving: any ConnectivityObserving,
        logger: any LogStoring
    ) {
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting
        self.wifiNetworkProviding = wifiNetworkProviding
        self.connectivityObserving = connectivityObserving
        self.logger = logger

        // Initialize current state
        self.isAutoSecureEnabled = preferencesReading.autoSecureNewNetworks
        self.networks = wifiNetworkProviding.networks
        self.currentNetwork = connectivityObserving.currentNetwork
    }

    // MARK: - Lifecycle
    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let autoSecure: () = observeAutoSecure()
        async let wifiNetworks: () = observeWifiNetworks()
        async let connectivity: () = observeConnectivity()

        _ = await (autoSecure, wifiNetworks, connectivity)
    }

    private func observeAutoSecure() async {
        for await value in preferencesReading.autoSecureUpdates {
            isAutoSecureEnabled = value
        }
    }

    private func observeWifiNetworks() async {
        for await value in wifiNetworkProviding.networksUpdates {
            networks = value
        }
    }

    private func observeConnectivity() async {
        for await value in connectivityObserving.networkUpdates {
            currentNetwork = value
        }
    }

    // MARK: - Actions (called by the view)
    func entrySelected(_ entry: NetworkOptionsEntryType, action: MenuEntryActionResponseType) {
        switch entry {
        case .autoSecure:
            if case .toggle(let isSelected, _) = action {
                preferencesWriting.saveAutoSecureNewNetworks(autoSecure: isSelected)
            } else if case .infoLink = action {
                openLink(.networkOptions)
            }

        case let .network(info):
            navigateToNetwork(named: info.name)

        case let .networkList(info, otherNetworks):
            if case .button(let parentId) = action {
                if entry.id == parentId {
                    navigateToNetwork(named: info.name)
                } else {
                    let index = parentId / 20
                    if index < otherNetworks.count {
                        navigateToNetwork(named: otherNetworks[index].name)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods
    private func getCurrentWifiNetwork() -> WifiNetworkModel? {
        guard let currentSSID = currentNetwork?.name else { return nil }
        return networks.first { $0.SSID == currentSSID }
    }

    private func openLink(_ linkType: FeatureExplainer) {
        if let url = URL(string: linkType.getUrl()) {
            safariURL = url
            showingSafari = true
        }
    }

    private func navigateToNetwork(named: String) {
        if let network = wifiNetworkProviding.findNetwork(with: named) {
            navigationRoute = .networkSettings(network: network)
        }
    }
}

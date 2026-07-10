//
//  NetworkSettingsScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class NetworkSettingsScreenViewModel {
    // MARK: - Dependencies
    private let wifiNetworkProviding: any WifiNetworkProviding
    private let wifiNetworkManaging: any WifiNetworkManaging
    private let connectivityObserving: any ConnectivityObserving
    private let portMapProviding: any PortMapProviding
    private let vpnStateProviding: any VPNStateProviding
    private let protocolManaging: any ProtocolManaging
    private let vpnOnDemandManaging: any VPNOnDemandManaging
    private let logger: any LogStoring

    // MARK: - State
    private var displayingNetwork: WifiNetworkModel
    private var isObserving = false
    var shouldDismiss = false

    init(
        network: WifiNetworkModel,
        wifiNetworkProviding: any WifiNetworkProviding,
        wifiNetworkManaging: any WifiNetworkManaging,
        connectivityObserving: any ConnectivityObserving,
        portMapProviding: any PortMapProviding,
        vpnStateProviding: any VPNStateProviding,
        protocolManaging: any ProtocolManaging,
        vpnOnDemandManaging: any VPNOnDemandManaging,
        logger: any LogStoring
    ) {
        self.displayingNetwork = network
        self.wifiNetworkProviding = wifiNetworkProviding
        self.wifiNetworkManaging = wifiNetworkManaging
        self.connectivityObserving = connectivityObserving
        self.portMapProviding = portMapProviding
        self.vpnStateProviding = vpnStateProviding
        self.protocolManaging = protocolManaging
        self.vpnOnDemandManaging = vpnOnDemandManaging
        self.logger = logger
    }

    // MARK: - Computed Properties
    var entries: [NetworkSettingsEntryTpe] {
        let protocolOptions = getProtocols()
            .map { MenuOption(title: $0, fieldKey: $0) }
        let portOptions = getPorts(by: displayingNetwork.preferredProtocol)
            .map { MenuOption(title: $0, fieldKey: $0) }

        var result: [NetworkSettingsEntryTpe] = [
            .autoSecure(isSelected: !displayingNetwork.status),
            .preferredProtocol(
                isSelected: displayingNetwork.preferredProtocolStatus == true && displayingNetwork.status == false,
                protocolSelected: displayingNetwork.preferredProtocol,
                protocolOptions: protocolOptions,
                portSelected: displayingNetwork.preferredPort,
                portOptions: portOptions
            )
        ]

        // Only show forget button if not on current network
        if connectivityObserving.currentNetwork.name != displayingNetwork.SSID {
            result.append(.forget)
        }

        return result
    }

    // MARK: - Observers
    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let networks: () = observeWifiNetworks()

        _ = await networks
    }

    private func observeWifiNetworks() async {
        for await networks in wifiNetworkProviding.networksUpdates {
            // Update the displayed network with fresh data
            if let updated = networks.first(where: { $0.SSID == displayingNetwork.SSID }) {
                displayingNetwork = updated
            }
        }
    }

    // MARK: - Actions
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

    // MARK: - Private Methods
    private func updatePreferredProtocolSwitch(_ status: Bool) {
        guard displayingNetwork.status == false else { return }
        wifiNetworkManaging.updateNetworkPreferredProtocolStatus(
            network: displayingNetwork,
            status: status
        )
    }

    private func updatePreferredProtocol(value: String) {
        let port = getPorts(by: value).first ?? DefaultValues.port
        wifiNetworkManaging.updateNetworkPreferredProtocol(
            network: displayingNetwork,
            protocol: value,
            port: port
        )

        Task {
            logger.logI("NetworkSettingsScreenViewModel", "updatePreferredProtocol for getNextProtocol")
            await protocolManaging.refreshProtocols(
                shouldReset: true,
                shouldReconnect: vpnStateProviding.isConnected()
            )
        }
    }

    private func updatePreferredPort(value: String) {
        wifiNetworkManaging.updateNetworkPreferredPort(
            network: displayingNetwork,
            port: value
        )
    }

    private func getPorts(by protocolType: String) -> [String] {
        return portMapProviding.getPorts(protocolType: protocolType) ?? []
    }

    private func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    private func updateTrustNetwork(_ status: Bool) {
        wifiNetworkManaging.updateNetworkTrustStatus(
            network: displayingNetwork,
            trusted: status
        )
        vpnOnDemandManaging.updateOnDemandRules()
    }

    private func forgetNetwork() {
        wifiNetworkManaging.removeNetwork(network: displayingNetwork)
        shouldDismiss = true
    }
}

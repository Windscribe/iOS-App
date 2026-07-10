//
//  ConnectionScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Routes for Connection screen navigation.
enum ConnectionRoute: Hashable {
    case networkOptions
    case antiCensorshipOptions
}

@available(iOS 17.0, *)
@Observable
@MainActor
final class ConnectionScreenViewModel {

    // MARK: - Private State
    private var isObserving = false
    private var currentProtocol: String = DefaultValues.protocol
    private var currentPort: String = DefaultValues.port
    private var killSwitchSelected: Bool = DefaultValues.killSwitch
    private var allowLanSelected: Bool = DefaultValues.allowLANMode
    private var connectionMode: String = DefaultValues.connectionMode
    private var connectedDNS: String = DefaultValues.connectedDNS
    private var customDNSValue: String = DefaultValues.customDNSValue.value
    private var egressProtocol: String = DefaultValues.ipStack
    private var ingressProtocol: String = DefaultValues.ipStack

    // MARK: - Dependencies
    private let preferencesReading: any PreferencesReading
    private let preferencesWriting: any PreferencesWriting
    private let portMapProviding: any PortMapProviding
    private let dnsSettingsManaging: any DNSSettingsManaging
    private let logger: any LogStoring

    // MARK: - Published State
    var navigationRoute: ConnectionRoute? {
        didSet {
            isNavigating = navigationRoute != nil
        }
    }
    var isNavigating: Bool = false
    var safariURL: URL?
    var showingSafari: Bool = false

    // MARK: - Entries
    var entries: [ConnectionsEntryType] {
        let customDNSValue = preferencesReading.customDNSValue

        let connectionModes = zip(TextsAsset.connectionModes, Fields.connectionModes)
            .map { MenuOption(title: $0, fieldKey: $1) }

        let connectedDNSOptions = zip(TextsAsset.connectedDNSOptions, Fields.connectedDNSOptions)
            .map { MenuOption(title: $0, fieldKey: $1) }

        let protocolOptions = getProtocols()
            .map { MenuOption(title: $0, fieldKey: $0) }

        let portOptions = getPorts(by: currentProtocol)
            .map { MenuOption(title: $0, fieldKey: $0) }

        let ipStackOptions = zip(TextsAsset.ipStackOptions, Fields.ipStackOptions)
            .map { MenuOption(title: $0, fieldKey: $1) }

        var result: [ConnectionsEntryType] = [
            .networkOptions,
            .antiCensorshipOptions,
            .connectionMode(
                currentOption: connectionMode,
                options: connectionModes,
                protocolSelected: currentProtocol,
                protocolOptions: protocolOptions,
                portSelected: currentPort,
                portOptions: portOptions
            ),
            .ipStack(
                selectedEgressOption: egressProtocol,
                egressOptions: ipStackOptions,
                selectedIngressOption: ingressProtocol,
                ingressOptions: ipStackOptions
            )
        ]

        // Only show Connected DNS if not IKEv2 or connection mode is auto
        if currentProtocol != VPNProtocolType.iKEv2.identifier || connectionMode == Fields.Values.auto {
            result.append(.connectedDns(
                currentOption: connectedDNS,
                customValue: customDNSValue,
                options: connectedDNSOptions
            ))
        }

        result.append(contentsOf: [
            .alwaysOn(isSelected: killSwitchSelected),
            .allowLan(isSelected: allowLanSelected)
        ])

        return result
    }

    // MARK: - Initialization
    init(
        preferencesReading: any PreferencesReading,
        preferencesWriting: any PreferencesWriting,
        portMapProviding: any PortMapProviding,
        dnsSettingsManaging: any DNSSettingsManaging,
        logger: any LogStoring
    ) {
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting
        self.portMapProviding = portMapProviding
        self.dnsSettingsManaging = dnsSettingsManaging
        self.logger = logger

        // Initialize current state from preferences
        currentProtocol = preferencesReading.selectedProtocol ?? DefaultValues.protocol
        currentPort = preferencesReading.selectedPort ?? DefaultValues.port
        killSwitchSelected = preferencesReading.killSwitchEnabled
        allowLanSelected = preferencesReading.allowLAN
        connectionMode = preferencesReading.connectionMode ?? DefaultValues.connectionMode
        connectedDNS = preferencesReading.connectedDNS ?? DefaultValues.connectedDNS
        customDNSValue = preferencesReading.customDNSValue
        egressProtocol = preferencesReading.egressProtocol ?? DefaultValues.ipStack
        ingressProtocol = preferencesReading.ingressProtocol ?? DefaultValues.ipStack
    }

    // MARK: - Lifecycle
    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let selectedProtocol: () = observeSelectedProtocol()
        async let port: () = observeSelectedPort()
        async let killSwitch: () = observeKillSwitch()
        async let allowLAN: () = observeAllowLAN()
        async let connMode: () = observeConnectionMode()
        async let dns: () = observeConnectedDNS()
        async let egress: () = observeEgressProtocol()
        async let ingress: () = observeIngressProtocol()

        _ = await (selectedProtocol, port, killSwitch, allowLAN, connMode, dns, egress, ingress)
    }

    private func observeSelectedProtocol() async {
        for await value in preferencesReading.selectedProtocolUpdates {
            currentProtocol = value ?? DefaultValues.protocol
        }
    }

    private func observeSelectedPort() async {
        for await value in preferencesReading.selectedPortUpdates {
            currentPort = value ?? DefaultValues.port
        }
    }

    private func observeKillSwitch() async {
        for await value in preferencesReading.killSwitchUpdates {
            killSwitchSelected = value
        }
    }

    private func observeAllowLAN() async {
        for await value in preferencesReading.allowLANUpdates {
            allowLanSelected = value
        }
    }

    private func observeConnectionMode() async {
        for await value in preferencesReading.connectionModeUpdates {
            connectionMode = (value ?? DefaultValues.connectionMode).localized
        }
    }

    private func observeConnectedDNS() async {
        for await value in preferencesReading.connectedDNSUpdates {
            connectedDNS = (value ?? DefaultValues.connectedDNS).localized
        }
    }

    private func observeEgressProtocol() async {
        for await value in preferencesReading.egressProtocolUpdates {
            egressProtocol = value ?? DefaultValues.ipStack
        }
    }

    private func observeIngressProtocol() async {
        for await value in preferencesReading.ingressProtocolUpdates {
            ingressProtocol = value ?? DefaultValues.ipStack
        }
    }

    // MARK: - Actions (called by the view)
    func entrySelected(_ entry: ConnectionsEntryType, action: MenuEntryActionResponseType) {
        switch entry {
        case .networkOptions:
            if case .button = action {
                navigationRoute = .networkOptions
            }
            if case .infoLink = action {
                openLink(.networkOptions)
            }

        case .connectionMode:
            if case .multiple(let currentOption, let parentId) = action {
                if parentId == ConnectionSecondaryEntryIDs.protocolMenu.id {
                    updateProtocol(value: currentOption)
                } else if parentId == ConnectionSecondaryEntryIDs.portMenu.id {
                    updatePort(value: currentOption)
                } else {
                    preferencesWriting.saveConnectionMode(mode: currentOption)
                }
            }
            if case .infoLink = action {
                openLink(.connectionModes)
            }

        case .connectedDns:
            if case .multiple(let currentOption, _) = action {
                preferencesWriting.saveConnectedDNS(mode: currentOption)
            }
            if case .infoLink = action {
                openLink(.connectedDNS)
            }
            if case .field(let value, _) = action {
                saveConnectedDNSValue(value: value)
            }

        case .alwaysOn:
            if case .toggle(let isSelected, _) = action {
                preferencesWriting.saveKillSwitch(killSwitch: isSelected)
            }

        case .allowLan:
            if case .toggle(let isSelected, _) = action {
                preferencesWriting.saveAllowLAN(mode: isSelected)
            }
            if case .infoLink = action {
                openLink(.allowLan)
            }

        case .antiCensorshipOptions:
            if case .button = action {
                navigationRoute = .antiCensorshipOptions
            }

        case .ipStack:
            if case .infoLink = action {
                openLink(.networkOptions)
            }
            if case let .multiple(currentOption, parentId) = action {
                if parentId == ConnectionSecondaryEntryIDs.ipStackEgressMenu.id {
                    preferencesWriting.saveEgressProtocolPreference(value: currentOption)
                } else if parentId == ConnectionSecondaryEntryIDs.ipStackIngressMenu.id {
                    preferencesWriting.saveIngressProtocolPreference(value: currentOption)
                }
            }
        }
    }

    // MARK: - Private Methods
    private func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    private func getPorts(by protocolType: String) -> [String] {
        guard let portsArray = portMapProviding.getPorts(protocolType: protocolType) else { return [] }
        return portsArray
    }

    private func updateProtocol(value: String) {
        preferencesWriting.saveSelectedProtocol(selectedProtocol: value)
        if let port = portMapProviding.getPorts(protocolType: value)?.first {
            preferencesWriting.saveSelectedPort(port: port)
        }
    }

    private func updatePort(value: String) {
        preferencesWriting.saveSelectedPort(port: value)
    }

    private func saveConnectedDNSValue(value: String) {
        // Handle empty string (X button clicked) - reset to default empty DNS
        if value.isEmpty {
            self.preferencesWriting.saveCustomDNSValue(value: DefaultValues.customDNSValue)
            self.customDNSValue = DefaultValues.customDNSValue.value
            return
        }

        dnsSettingsManaging.getDNSValue(
            from: value,
            completionDNS: { [weak self] dnsValue in
                guard let self, let dnsValue, !dnsValue.servers.isEmpty else {
                    return
                }
                Task { @MainActor in
                    self.preferencesWriting.saveCustomDNSValue(value: dnsValue)
                    self.customDNSValue = dnsValue.value
                }
            },
            completion: { _ in }
        )
    }

    private func openLink(_ linkType: FeatureExplainer) {
        if let url = URL(string: linkType.getUrl()) {
            safariURL = url
            showingSafari = true
        }
    }
}

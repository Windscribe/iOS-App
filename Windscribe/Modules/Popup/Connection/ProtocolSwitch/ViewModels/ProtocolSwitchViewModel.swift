//
//  ProtocolSwitchViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ProtocolSwitchViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var shouldDismiss: Bool { get }
    var shouldNavigateToResult: ProtocolViewDetails? { get set }
    var protocols: [ProtocolDisplayItem] { get }
    var fallbackType: ProtocolFallbacksType { get }
    var errorDescription: String? { get }

    func selectProtocol(_ protocolItem: ProtocolDisplayItem)
    func cancelSelection()
    func dismiss()
}

final class ProtocolSwitchViewModelImpl: ProtocolSwitchViewModel, ObservableObject {

    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var shouldNavigateToResult: ProtocolViewDetails?
    @Published var protocols: [ProtocolDisplayItem] = []
    @Published var fallbackType: ProtocolFallbacksType = .change
    @Published var errorDescription: String?

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let protocolManager: ProtocolManagerType
    private let vpnStateRepository: VPNStateRepository
    private let vpnManager: VPNManager
    private let localDatabase: LocalDatabase
    private let securedNetwork: SecuredNetworkRepository
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Reactive Triggers
    private let protocolSelectionTrigger = PassthroughSubject<(ProtocolPort, ConnectionType), Never>()
    private let disconnectTrigger = PassthroughSubject<Void, Never>()

    // MARK: - Initialization
    init(
        lookAndFeelRepository: LookAndFeelRepositoryType,
        protocolManager: ProtocolManagerType,
        vpnStateRepository: VPNStateRepository,
        vpnManager: VPNManager,
        localDatabase: LocalDatabase,
        securedNetwork: SecuredNetworkRepository,
        logger: FileLogger
    ) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.protocolManager = protocolManager
        self.vpnStateRepository = vpnStateRepository
        self.vpnManager = vpnManager
        self.localDatabase = localDatabase
        self.securedNetwork = securedNetwork
        self.logger = logger

        isDarkMode = lookAndFeelRepository.isDarkMode

        setupBindings()
        updateProtocolFlags()
    }

    private func setupBindings() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)

        protocolManager.failOverTimerCompletedSubject
            .sink { [weak self] in
                self?.logger.logI("ProtocolSwitchViewModel", "fail Over Timer Completed")
                self?.shouldDismiss = true
            }
            .store(in: &cancellables)

        protocolManager.displayProtocolsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] displayProtocols in
                guard !displayProtocols.isEmpty  else { return }
                self?.updateDisplayProtocols(displayProtocols)
            }
            .store(in: &cancellables)

        // Protocol selection reactive handling
        protocolSelectionTrigger
            .sink { [weak self] protocolPort, connectionType in
                self?.handleProtocolSelection(protocolPort, connectionType: connectionType)
            }
            .store(in: &cancellables)

        // Disconnect reactive handling
        disconnectTrigger
            .sink { [weak self] in
                self?.handleDisconnect()
            }
            .store(in: &cancellables)
    }

    /// Updates VPN manager flags based on connection state
    /// This handles the protocol switching context (failover vs manual change)
    private func updateProtocolFlags() {
        let isConnected = vpnStateRepository.isConnected()
        vpnStateRepository.setIsFromProtocolFailover(!isConnected)
        vpnStateRepository.setIsFromProtocolChange(isConnected)

        logger.logI("ProtocolSwitchViewModel",
                   "Protocol flags - failover: \(!isConnected), change: \(isConnected)")
    }

    // MARK: Protocol Loading and Management
    private func updateDisplayProtocols(_ displayProtocols: [DisplayProtocolPort]) {
        var protocolItems = displayProtocols.map { displayProtocol in
            ProtocolDisplayItem(
                protocolName: displayProtocol.protocolPort.protocolName,
                portName: displayProtocol.protocolPort.portName,
                description: getProtocolDescription(displayProtocol.protocolPort.protocolName),
                viewType: displayProtocol.viewType
            )
        }

        // If we're currently connected, ensure the connected protocol shows the "Connected to" badge
        if vpnStateRepository.isConnected(),
           let vpnInfo = vpnStateRepository.vpnInfo.value {
            // Find the connected protocol in the list and recreate it with .connected viewType
            if let index = protocolItems.firstIndex(where: {
                $0.protocolName == vpnInfo.selectedProtocol && $0.portName == vpnInfo.selectedPort
            }) {
                let connectedItem = protocolItems[index]
                protocolItems[index] = ProtocolDisplayItem(
                    protocolName: connectedItem.protocolName,
                    portName: connectedItem.portName,
                    description: connectedItem.description,
                    viewType: .connected
                )
            }
        }

        self.protocols = protocolItems
        logger.logI("ProtocolSwitchViewModel", "Loaded \(protocolItems.count) protocols")
    }

    /// Maps protocol names to their user-friendly descriptions
    private func getProtocolDescription(_ protocolName: String) -> String {
        switch protocolName {
        case iKEv2:
            return TextsAsset.ProtocolVariation.ikev2ProtocolDescription
        case udp:
            return TextsAsset.ProtocolVariation.udpProtocolDescription
        case tcp:
            return TextsAsset.ProtocolVariation.tcpProtocolDescription
        case wsTunnel:
            return TextsAsset.ProtocolVariation.wsTunnelProtocolDescription
        case stealth:
            return TextsAsset.ProtocolVariation.stealthProtocolDescription
        case wireGuard:
            return TextsAsset.ProtocolVariation.wireGuardProtocolDescription
        default:
            return ""
        }
    }

    // MARK: User Actions

    /// Handles user protocol selection - both manual selection and connected protocol info
    func selectProtocol(_ protocolItem: ProtocolDisplayItem) {
        logger.logI("ProtocolSwitchViewModel",
                   "User selected protocol: \(protocolItem.protocolName):\(protocolItem.portName)")

        switch protocolItem.viewType {
        case .connected:
            // User tapped connected protocol - check if already set as preferred
            if shouldShowPreferredProtocolPopup(for: protocolItem.protocolName) {
                shouldNavigateToResult = ProtocolViewDetails(protocolName: protocolItem.protocolName, viewType: protocolItem.viewType)
            } else {
                shouldDismiss = true
            }

        case .normal, .nextUp:
            // User manually selected a protocol to connect with
            let connectionType: ConnectionType = .failover
            protocolSelectionTrigger.send((protocolItem.protocolPort, connectionType))

        case .fail, .manualFail:
            // Failed protocols are not selectable - this shouldn't happen due to UI state
            logger.logI("ProtocolSwitchViewModel", "Attempted to select failed protocol")
        }
    }

    /// Checks if we should show the "Set as Preferred Protocol" popup
    /// Returns true if the protocol is NOT already set as preferred for the current network
    private func shouldShowPreferredProtocolPopup(for protocolName: String) -> Bool {
        guard let network = securedNetwork.getCurrentNetwork() else {
            return true // Show popup if we can't determine network
        }

        // Don't show popup if protocol is already set as preferred
        if network.preferredProtocolStatus && network.preferredProtocol == protocolName {
            return false
        }

        return true
    }

    func dismiss() {
        // Cancel any active failover timer to prevent automatic protocol switching
        protocolManager.cancelFailoverTimer()
        logger.logI("ProtocolSwitchViewModel", "Pressed to Dismiss")
        shouldDismiss = true
    }

    /// Handles cancel button action based on current connection state
    func cancelSelection() {
        // Always cancel any active failover timer when user cancels
        protocolManager.cancelFailoverTimer()

        if vpnStateRepository.isConnected() {
            // Connected state - just dismiss the dialog
            logger.logI("ProtocolSwitchViewModel", "Canceling protocol selection - connected")
            shouldDismiss = true
        } else {
            // Not connected - trigger disconnect and reset failure counts
            logger.logI("ProtocolSwitchViewModel", "Canceling protocol selection - disconnecting")
            AutomaticMode.shared.resetFailCounts()
            disconnectTrigger.send()
        }
    }

    /// Handles the actual protocol selection by calling ProtocolManager
    /// This is where the reactive pattern replaces the old callback-based approach
    private func handleProtocolSelection(_ protocolPort: ProtocolPort, connectionType: ConnectionType) {
        protocolManager.onUserSelectProtocol(proto: protocolPort, connectionType: connectionType)
        shouldDismiss = true

        logger.logI("ProtocolSwitchViewModel",
                   "Protocol selection handled: \(protocolPort) type: \(connectionType)")
    }

    /// Handles disconnect action through reactive pattern
    private func handleDisconnect() {
        logger.logI("ProtocolSwitchViewModel", "Disconnect handled - disabling VPN connection")
        disableVPNConnection()
        shouldDismiss = true
    }

    /// Disables VPN connection with trusted network logic
    private func disableVPNConnection() {
        guard !WifiManager.shared.isConnectedWifiTrusted() else {
            logger.logI("ProtocolSwitchViewModel", "User leaving untrusted network")
            vpnStateRepository.setUntrustedOneTimeOnlySSID("")
            vpnManager.simpleDisableConnection()
            return
        }

        // For trusted networks, use the full disconnect process from ConnectionViewModel
        let disconnectPublisher = vpnManager.disconnectFromViewModel()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    self.logger.logI("ProtocolSwitchViewModel", "Finished disabling connection.")
                case let .failure(error):
                    self.logger.logE("ProtocolSwitchViewModel", "Disable connection error: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                // Disconnection event received - main logic handled in completion block
            }

        // Store the cancellable so it doesn't get deallocated
        disconnectPublisher.store(in: &cancellables)
    }
}

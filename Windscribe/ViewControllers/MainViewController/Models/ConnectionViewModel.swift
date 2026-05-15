//
//  ConnectionViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine
import NetworkExtension
#if canImport(WidgetKit)
import WidgetKit
#endif

protocol ConnectionViewModelType {
    var connectedState: CurrentValueSubject<ConnectionStateInfo, Never> { get }
    var selectedProtoPort: CurrentValueSubject<ProtocolPort?, Never> { get }
    var selectedLocationUpdated: CurrentValueSubject<Void, Never> { get }

    var loadLatencyValuesSubject: PassthroughSubject<LoadLatencyInfo, Never> {get}
    var showFailedPinIpTrigger: PassthroughSubject<Void, Never> { get }
    var showUpgradeRequiredTrigger: PassthroughSubject<Void, Never> { get }
    var showPrivacyTrigger: PassthroughSubject<Void, Never> { get }
    var showAuthFailureTrigger: PassthroughSubject<Void, Never> { get }
    var showConnectionFailedTrigger: PassthroughSubject<Void, Never> { get }
    var showNoConnectionAlertTrigger: PassthroughSubject<Void, Never> { get }
    var pushNotificationPermissionsTrigger: PassthroughSubject<Void, Never> { get }
    var siriShortcutTrigger: PassthroughSubject<Void, Never> { get }
    var showEditCustomConfigTrigger: PassthroughSubject<CustomConfigModel, Never> { get }
    var reloadLocationsTrigger: PassthroughSubject<String, Never> { get }
    var reviewRequestTrigger: PassthroughSubject<Void, Never> { get }
    var showPreferredProtocolView: PassthroughSubject<String, Never> { get }

    var vpnManager: VPNManager { get }
    var appReviewManager: AppReviewManaging { get }

    // Check State
    func isConnected() -> Bool
    func isConnecting() -> Bool
    func isDisconnected() -> Bool
    func isDisconnecting() -> Bool
    func isInvalid() -> Bool
    func isProtocolSwitchInProgress() -> Bool

    // Actions
    func setOutOfData()
    func enableConnection()
    func disableConnection()
    func saveLastConnectionTarget(with locationID: String)
    func selectBestLocation(with locationID: String)
    func updateLoadLatencyValuesOnDisconnect(with value: Bool)
    func displayLocalIPAddress()
    func checkForForceDisconnect()
    func checkForPrivacyConsent()

    // Info
    func getSelectedCountryCode() -> String
    func getSelectedCountryInfo() -> LocationUIInfo
    func isBestLocationSelected() -> Bool
    func isCustomConfigSelected() -> Bool
    func getBestLocationId() -> Int
    func getBestLocation() -> BestLocationModel?
    func getConnectionTargetType() -> ConnectionTargetType?
    func isNetworkCellularWhileConnecting(for network: WifiNetworkModel?) -> Bool
    func isNetworkCellularWhileConnecting(for network: AppNetwork?) -> Bool
}

class ConnectionViewModel: ConnectionViewModelType {
    let connectedState = CurrentValueSubject<ConnectionStateInfo, Never>( ConnectionStateInfo.defaultValue())
    let selectedProtoPort = CurrentValueSubject<ProtocolPort?, Never>(nil)
    let selectedLocationUpdated = CurrentValueSubject<Void, Never>(())

    let showFailedPinIpTrigger: PassthroughSubject<Void, Never>

    var loadLatencyValuesSubject = PassthroughSubject<LoadLatencyInfo, Never>()
    let showUpgradeRequiredTrigger = PassthroughSubject<Void, Never>()
    let showPrivacyTrigger = PassthroughSubject<Void, Never>()
    let showAuthFailureTrigger = PassthroughSubject<Void, Never>()
    let showConnectionFailedTrigger = PassthroughSubject<Void, Never>()
    let pushNotificationPermissionsTrigger = PassthroughSubject<Void, Never>()
    let siriShortcutTrigger = PassthroughSubject<Void, Never>()
    let showEditCustomConfigTrigger = PassthroughSubject<CustomConfigModel, Never>()
    let showNoConnectionAlertTrigger = PassthroughSubject<Void, Never>()
    let reloadLocationsTrigger = PassthroughSubject<String, Never>()
    let reviewRequestTrigger = PassthroughSubject<Void, Never>()
    let showPreferredProtocolView = PassthroughSubject<String, Never>()

    let combineVpnInfo = PassthroughSubject<VPNConnectionInfo?, Never>()

    private var cancellables = Set<AnyCancellable>()

    let vpnManager: VPNManager
    let vpnStateRepository: VPNStateRepository
    let logger: FileLogger
    let apiManager: APIManager
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType
    let preferences: Preferences
    let connectivity: ConnectivityManager
    let wifiManager: WifiManager
    let wifiNetworkRepository: WifiNetworkRepository
    let credentialsRepository: CredentialsRepository
    let ipRepository: IPRepository
    let appReviewManager: AppReviewManaging
    let customSoundPlaybackManager: CustomSoundPlaybackManaging
    let privacyStateManager: PrivacyStateManaging
    let userSessionRepository: UserSessionRepository
    let locationListRepository: LocationListRepository

    private var connectionTaskPublisher: AnyCancellable?
    private var gettingIpAddress = false
    private var loadLatencyValuesOnDisconnect = false
    private var currentNetwork: AppNetwork?
    private var currentWifiAutoSecured = false

    private var currentConnectionType: ConnectionType = .user

    init(logger: FileLogger,
         apiManager: APIManager,
         vpnManager: VPNManager,
         vpnStateRepository: VPNStateRepository,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType,
         preferences: Preferences,
         connectivity: ConnectivityManager,
         wifiManager: WifiManager,
         wifiNetworkRepository: WifiNetworkRepository,
         credentialsRepository: CredentialsRepository,
         ipRepository: IPRepository,
         customSoundPlaybackManager: CustomSoundPlaybackManaging,
         privacyStateManager: PrivacyStateManaging,
         userSessionRepository: UserSessionRepository,
         locationListRepository: LocationListRepository) {
        self.logger = logger
        self.apiManager = apiManager
        self.vpnManager = vpnManager
        self.vpnStateRepository = vpnStateRepository
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
        self.preferences = preferences
        self.connectivity = connectivity
        self.wifiManager = wifiManager
        self.wifiNetworkRepository = wifiNetworkRepository
        self.ipRepository = ipRepository
        self.credentialsRepository = credentialsRepository
        self.customSoundPlaybackManager = customSoundPlaybackManager
        self.privacyStateManager = privacyStateManager
        self.userSessionRepository = userSessionRepository
        self.locationListRepository = locationListRepository

        appReviewManager = AppReviewManager(preferences: preferences, logger: logger)

        showFailedPinIpTrigger = vpnManager.showFailedPinIpTrigger

        vpnStateRepository.getStatus()
            .sink { [weak self] state in
                guard let self = self else { return }
                self.updateState(with: ConnectionState.state(from: state))
                self.saveDataForWidget()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(vpnStateRepository.vpnInfo, protocolManager.currentProtocolSubject)
            .sink { [weak self] (info, nextProtocol) in
                guard let self = self else { return }
                if info == nil && nextProtocol == nil {
                    self.selectedProtoPort.send(protocolManager.getProtocol())
                } else if let info = info, [.connected, .connecting].contains(info.status) {
                    self.selectedProtoPort.send(ProtocolPort(info.selectedProtocol, info.selectedPort))
                } else if let nextProtocol = nextProtocol {
                    self.selectedProtoPort.send(nextProtocol)
                }
            }
            .store(in: &cancellables)

        protocolManager.connectionProtocolSubject
            .sink { [weak self] value in
                guard let self = self, let value = value else { return }
                // Only block if actually connected, not just matching protocol
                if let info = vpnStateRepository.vpnInfo.value,
                   info.selectedProtocol == value.protocolPort.protocolName,
                   info.status == .connected {
                    return
                }
                self.enableConnection(connectionType: value.connectionType)
            }
            .store(in: &cancellables)

        locationsManager.selectedLocationUpdated.sink { [weak self] canReconnect in
            guard let self = self else { return }
            let locationID = locationsManager.getLastConnectionTarget()
            if canReconnect, !locationID.isEmpty, locationID != "0", self.isConnected() {
                self.enableConnection()
            }
            self.selectedLocationUpdated.send(())
        }.store(in: &cancellables)

        connectivity.network.removeDuplicates()
        .sink { [weak self] network in
            guard let self = self else { return }
            guard network.networkType != .none else {
                return
            }
            guard network.name?.uppercased() != TextsAsset.NetworkSecurity.unknownNetwork.uppercased() else {
                return
            }
            if self.currentNetwork != nil, self.currentNetwork?.name != network.name {
                self.refreshConnectionFromNetworkChange()
            }
            self.currentNetwork = network
        }.store(in: &cancellables)

        wifiNetworkRepository.networks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wifiNetworks in
                guard let self = self else { return }
                let matchingNetwork = wifiNetworks.first { $0.SSID == self.currentNetwork?.name }
                guard let matchingNetwork = matchingNetwork else { return }
                if matchingNetwork.status == true, !self.currentWifiAutoSecured {
                    if self.isConnected() || self.isConnecting() {
                        self.disableConnection()
                    }
                }
                self.currentWifiAutoSecured = matchingNetwork.status
            }
            .store(in: &cancellables)

        appReviewManager.reviewRequestTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reviewRequestTrigger.send(())
            }
            .store(in: &cancellables)

        locationListRepository.datacenterListSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkForForceDisconnect()
            }
            .store(in: &cancellables)

    }
}

extension ConnectionViewModel {
    func updateLoadLatencyValuesOnDisconnect(with value: Bool) {
        loadLatencyValuesOnDisconnect = value
    }

    func isConnected() -> Bool {
        connectedState.value.state == .connected
    }

    func isConnecting() -> Bool {
        connectedState.value.state == .connecting
    }

    func isDisconnected() -> Bool {
        connectedState.value.state == .disconnected
    }

    func isDisconnecting() -> Bool {
        connectedState.value.state == .disconnecting
    }

    func isInvalid() -> Bool {
        connectedState.value.state == .invalid
    }

    func isProtocolSwitchInProgress() -> Bool {
        vpnStateRepository.isFromProtocolChange ||
        vpnStateRepository.isFromProtocolFailover ||
        vpnStateRepository.configurationState == .configuring
    }

    func isCustomConfigSelected() -> Bool {
        locationsManager.isCustomConfigSelected()
    }

    func isNetworkCellularWhileConnecting(for network: WifiNetworkModel?) -> Bool {
        if isConnecting() && network?.SSID == "Cellular" { return true }
        if isConnecting() || isConnected() {
            return connectivity.network.value.networkType == NetworkType.none
        }
        return false
    }

    func isNetworkCellularWhileConnecting(for network: AppNetwork?) -> Bool {
        if isConnecting() && network?.name == "Cellular" { return true }
        if (isConnecting() || isConnected()) && network?.networkType == NetworkType.none {
            return true
        }
        return false
    }

    func setOutOfData() {
        if isConnected(), !locationsManager.isCustomConfigSelected() {
            disableConnection()
        }
    }

    func getSelectedCountryCode() -> String {
        return getSelectedCountryInfo().countryCode
    }

    func getSelectedCountryInfo() -> LocationUIInfo {
        locationsManager.getLocationUIInfo()
    }

    func isBestLocationSelected() -> Bool {
        return String(locationsManager.getBestLocation()) == locationsManager.getLastConnectionTarget()
    }

    func saveLastConnectionTarget(with locationID: String) {
        locationsManager.saveLastConnectionTarget(with: locationID)
    }

    func selectBestLocation(with locationID: String) {
        locationsManager.selectBestLocation(with: locationID)
    }

    func getBestLocationId() -> Int {
        return locationsManager.getBestLocation()
    }

    func getBestLocation() -> BestLocationModel? {
        let bestLocationId = getBestLocationId()
        return locationsManager.getBestLocationModel(from: bestLocationId)
    }

    func getConnectionTargetType() -> ConnectionTargetType? {
        return locationsManager.getConnectionTargetType()
    }

    private func refreshConnectionFromNetworkChange() {
        if let info = vpnStateRepository.vpnInfo.value {
            if connectivity.getNetwork().name == nil || connectivity.getNetwork().name == "Unknown" {
                return
            }

            let network = wifiNetworkRepository.networks.value.filter {$0.SSID == connectivity.getNetwork().name}.first
            if .connected == info.status {
                wifiManager.saveCurrentWifiNetworks()
                var needsReconnect = false
                if !needsReconnect, network?.preferredProtocol == info.selectedProtocol  && network?.preferredPort == info.selectedPort {
                    return
                }
                connectionTaskPublisher?.cancel()
                connectionTaskPublisher = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.logger.logI("ConnectionViewModel", "refreshConnectionFromNetworkChange 1 for getNextProtocol")
                            await self.protocolManager.refreshProtocols(shouldReset: true,
                                                                        shouldReconnect: true)
                        }
                    } receiveValue: { _ in }
            } else if .connecting != info.status {
                Task { @MainActor in
                    self.logger.logI("ConnectionViewModel", "refreshConnectionFromNetworkChange 2 for getNextProtocol")
                    await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                }
            }
        }
    }

    func displayLocalIPAddress() {
        if !gettingIpAddress && !isConnecting() {
            logger.logD("ConnectionViewModel", "Displaying local IP Address.")
            gettingIpAddress = true
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.ipRepository.getIp()
                } catch {
                    // Error already logged in repository
                }
                await MainActor.run {
                    self.gettingIpAddress = false
                }
            }
        }
    }

    func checkForForceDisconnect() {
        if locationsManager.checkForForceDisconnect(), isConnected() {
            enableConnection()
        }
    }

    func enableConnection() {
        enableConnection(connectionType: .user)
    }

    private func enableConnection(connectionType: ConnectionType) {
        Task { @MainActor in
            guard !wifiManager.isConnectedWifiTrusted() else {
                logger.logI("ConnectionViewModel", "User joining untrusted network")

                let currentNetwork = wifiNetworkRepository.getCurrentNetwork()
                vpnStateRepository.setUntrustedOneTimeOnlySSID(currentNetwork?.SSID ?? "")
                vpnManager.simpleEnableConnection()
                return
            }

            if checkCanPlayDisconnectedSound() {
                playSound(for: .disconnected)
            }

            let nextProtocol = protocolManager.getProtocol()
            let locationID = locationsManager.getLastConnectionTarget()
            currentConnectionType = connectionType
            connectionTaskPublisher?.cancel()

            connectionTaskPublisher = vpnManager.connectFromViewModel(locationId: locationID, proto: nextProtocol, connectionType: connectionType)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.logger.logD("ConnectionViewModel", "Finished enabling connection.")
                    case let .failure(error):
                        if let error = error as? NEVPNError {
                            self.logger.logE("ConnectionViewModel", "NEVPNError: \(error.code)")
                            return
                        }
                        if let error = error as? VPNConfigurationErrors {
                            self.logger.logE("ConnectionViewModel", "Enable connection had a VPNConfigurationErrors: \(error.description)")
                            if !self.handleErrors(error: error, fromEnable: true) {
                                self.checkAutoModeFail()
                            }
                        } else {
                            self.logger.logE("ConnectionViewModel", "Enable Connection with unknown error: \(error.localizedDescription)")
                            if let error = error as? Errors, error != Errors.handled {
                                self.checkAutoModeFail()
                            }
                        }
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        self.logger.logD("ConnectionViewModel", "Enable connection had an update: \(message)")
                    case .validated:
                        self.logger.logD("ConnectionViewModel", "Enable connection validate")
                        self.updateState(with: .connected)
                        self.checkPreferencesForTriggers()
                        self.checkShouldShowPreferredProtocol()
                    case let .vpn(status):
                        self.logger.logI("ConnectionViewModel", "Enable connection new status: \(status.rawValue)")
                    case .validating:
                        self.updateState(with: .testing)
                    }
                })
        }
    }

    func disableConnection() {
        guard !wifiManager.isConnectedWifiTrusted() else {
            logger.logI("ConnectionViewModel", "User leaving untrusted network")
            vpnStateRepository.setUntrustedOneTimeOnlySSID("")
            vpnManager.simpleDisableConnection()
            return
        }

        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    self.logger.logD("ConnectionViewModel", "Finished disabling connection.")
                    self.displayLocalIPAddress()
                    Task { @MainActor in
                        self.logger.logI("ConnectionViewModel", "disableConnection for getNextProtocol")
                        await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                    }
                    if self.loadLatencyValuesOnDisconnect {
                        self.loadLatencyValuesOnDisconnect = false
                        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.loadLatencyValues), userInfo: nil, repeats: false)
                        return
                    }
                case let .failure(error):
                    if let error = error as? VPNConfigurationErrors {
                        self.logger.logE("ConnectionViewModel", "Disable connection had a VPNConfigurationErrors: \(error.description)")
                        _ = !self.handleErrors(error: error)
                    } else {
                        self.logger.logE("ConnectionViewModel", "Disable Connection with unknown error: \(error.localizedDescription)")
                    }
                }
            } receiveValue: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case let .update(message):
                    self.logger.logD("ConnectionViewModel", "Disable connection had an update: \(message)")
                case let .vpn(status):
                    self.logger.logI("ConnectionViewModel", "Disable connection new status: \(status.rawValue)")
                default: ()
                }
            }
    }

    @objc private func loadLatencyValues() {
        loadLatencyValuesSubject.send(LoadLatencyInfo(force: false, connectToBestLocation: true))
    }

    private func checkShouldShowPreferredProtocol() {
        guard currentConnectionType == .failover else { return }

        let network = wifiNetworkRepository.networks.value.first { $0.SSID == connectivity.getNetwork().name }
        guard let network = network else { return }

        let nextProtocol = protocolManager.getProtocol()
        guard !network.preferredProtocolStatus ||
                nextProtocol.protocolName != network.preferredProtocol else {
            return
        }

        showPreferredProtocolView.send(nextProtocol.protocolName)
    }

    private func checkPreferencesForTriggers() {
        let connectionCount = preferences.getConnectionCount()

        if connectionCount == 2 {
            logger.logD("ConnectionViewModel", "Displaying push notifications permission popup to user.")
            pushNotificationPermissionsTrigger.send(())
        }
        if connectionCount == 5 {
            logger.logD("ConnectionViewModel", "Displaying Siri shortcut popup.")
            siriShortcutTrigger.send(())
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let count = connectionCount, count % 3 == 0 else {
                logger.logD("ConnectionViewModel", "Rate Dialog: Connection count is not a multiple of 3. Skipping...")
                return
            }

            let activeSession = self.userSessionRepository.sessionModel
            self.appReviewManager.requestReviewIfAvailable(session: activeSession)
        }
    }

    // This should only be called when VPN is disconnected
    private func updateToLocalIPAddress() {
        logger.logD("ConnectionViewModel", "Displaying local IP Address.")
        gettingIpAddress = true
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.ipRepository.getIp()
            } catch {
                // Error already logged in repository
            }
            await MainActor.run {
                self.gettingIpAddress = false
            }
        }
    }

    private func saveDataForWidget() {
        let locationInfo = locationsManager.getLocationUIInfo()

        preferences.saveServerNameKey(key: locationInfo.cityName)
        preferences.saveNickNameKey(key: locationInfo.nickName)
        preferences.saveCountryCodeKey(key: locationInfo.countryCode)

        if credentialsRepository.selectedServerCredentialsType() == IKEv2ServerCredentials.self {
            preferences.setServerCredentialTypeKey(typeKey: VPNProtocolType.iKEv2.identifier)
        } else {
            preferences.setServerCredentialTypeKey(typeKey: TextsAsset.openVPN)
        }

#if os(iOS) && (arch(arm64) || arch(i386) || arch(x86_64))
        WidgetCenter.shared.reloadAllTimelines()
#endif
    }
}

extension ConnectionViewModel {
    func handleErrors(error: VPNConfigurationErrors, fromEnable: Bool = false) -> Bool {
        switch error {
        case .credentialsNotFound,
                .invalidConnectionTargetType,
                .customConfigSupportNotAvailable,
                .noValidServerFound,
                .invalidServerConfig,
                .configNotFound,
                .incorrectVPNManager,
                .connectionTimeout:
            return false
        case .accountExpired:
            showUpgradeRequiredTrigger.send(())
        case .accountBanned:
            return true
        case .locationNotFound(let id):
            reloadLocationsTrigger.send(String(id))
        case .networkIsOffline:
            showNoConnectionAlertTrigger.send(())
        case .upgradeRequired:
            showUpgradeRequiredTrigger.send(())
        case .privacyNotAccepted:
            showPrivacyTrigger.send(())
        case .authFailure:
            showAuthFailureTrigger.send(())
        case .connectivityTestFailed:
            guard locationsManager.getConnectionTargetType() == .custom else { return false }
            showAuthFailureTrigger.send(())
        case let .customConfigMissingCredentials(customConfig):
            showEditCustomConfigTrigger.send(customConfig)
        }
        return true
    }

    func checkAutoModeFail() {
        Task {
            await protocolManager.onProtocolFail()
        }
    }

    func updateState(with state: ConnectionState) {
        if !gettingIpAddress, state == .disconnected, !isDisconnected() {
            displayLocalIPAddress()
        }

        if connectedState.value.state != state {
            playSound(for: state, previousState: connectedState.value.state)
        }

        connectedState.send(ConnectionStateInfo(state: state,
                                                isCustomConfigSelected: self.locationsManager.isCustomConfigSelected(),
                                                internetConnectionAvailable: false,
                                                connectedWifi: nil))

    }

    func checkForPrivacyConsent() {
        privacyStateManager.privacyAcceptedSubject
            .prefix(1) // Only take the first acceptance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.enableConnection()
            }
            .store(in: &cancellables)
    }

    private func checkCanPlayDisconnectedSound() -> Bool {
        return connectedState.value.state == .connected
    }

    private func playSound(for state: ConnectionState, previousState: ConnectionState? = nil) {
        // checking if previous state is testing or connecting helps distinction from connected state on app launch
        if state == .connected, let previousState = previousState, previousState == .testing ||  previousState == .connecting {
            customSoundPlaybackManager.playSound(for: .connect)
        } else if state == .disconnected {
            customSoundPlaybackManager.playSound(for: .disconnect)
        } else if state == .connecting {
            customSoundPlaybackManager.playSound(for: .connect, isConnecting: true)
        }
    }
}

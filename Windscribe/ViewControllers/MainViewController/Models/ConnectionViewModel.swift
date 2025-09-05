//
//  ConnectionViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import NetworkExtension
#if canImport(WidgetKit)
import WidgetKit
#endif

protocol ConnectionViewModelType {
    var connectedState: BehaviorSubject<ConnectionStateInfo> { get }
    var selectedProtoPort: BehaviorSubject<ProtocolPort?> { get }
    var selectedLocationUpdatedSubject: BehaviorSubject<Void> { get }

    var loadLatencyValuesSubject: PublishSubject<LoadLatencyInfo> {get}
    var showUpgradeRequiredTrigger: PublishSubject<Void> { get }
    var showPrivacyTrigger: PublishSubject<Void> { get }
    var showAuthFailureTrigger: PublishSubject<Void> { get }
    var showConnectionFailedTrigger: PublishSubject<Void> { get }
    var showNoConnectionAlertTrigger: PublishSubject<Void> { get }
    var pushNotificationPermissionsTrigger: PublishSubject<Void> { get }
    var siriShortcutTrigger: PublishSubject<Void> { get }
    var showEditCustomConfigTrigger: PublishSubject<CustomConfigModel> { get }
    var reloadLocationsTrigger: PublishSubject<String> { get }
    var reviewRequestTrigger: PublishSubject<Void> { get }
    var showPreferredProtocolView: PublishSubject<String> { get }

    var vpnManager: VPNManager { get }
    var appReviewManager: AppReviewManaging { get }

    // Check State
    func isConnected() -> Bool
    func isConnecting() -> Bool
    func isDisconnected() -> Bool
    func isDisconnecting() -> Bool
    func isInvalid() -> Bool

    // Actions
    func refreshProtocols()
    func setOutOfData()
    func enableConnection()
    func disableConnection()
    func saveLastSelectedLocation(with locationID: String)
    func saveBestLocation(with locationID: String)
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
    func getBestLocationId() -> String
    func getBestLocation() -> BestLocationModel?
    func getLocationType() -> LocationType?
    func isNetworkCellularWhileConnecting(for network: WifiNetwork?) -> Bool
    func isNetworkCellularWhileConnecting(for network: AppNetwork?) -> Bool
}

class ConnectionViewModel: ConnectionViewModelType {
    let connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())
    let selectedProtoPort = BehaviorSubject<ProtocolPort?>(value: nil)
    let selectedLocationUpdatedSubject = BehaviorSubject<Void>(value: ())

    var loadLatencyValuesSubject = PublishSubject<LoadLatencyInfo>()
    let showUpgradeRequiredTrigger = PublishSubject<Void>()
    let showPrivacyTrigger = PublishSubject<Void>()
    let showAuthFailureTrigger = PublishSubject<Void>()
    let showConnectionFailedTrigger = PublishSubject<Void>()
    let pushNotificationPermissionsTrigger = PublishSubject<Void>()
    let siriShortcutTrigger = PublishSubject<Void>()
    let showEditCustomConfigTrigger = PublishSubject<CustomConfigModel>()
    let showNoConnectionAlertTrigger = PublishSubject<Void>()
    let reloadLocationsTrigger = PublishSubject<String>()
    let reviewRequestTrigger = PublishSubject<Void>()
    let showPreferredProtocolView = PublishSubject<String>()
    
    let combineVpnInfo = PassthroughSubject<VPNConnectionInfo?, Never>()

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    let vpnManager: VPNManager
    let logger: FileLogger
    let apiManager: APIManager
    let locationsManager: LocationsManagerType
    let protocolManager: ProtocolManagerType
    let preferences: Preferences
    let connectivity: Connectivity
    let wifiManager: WifiManager
    let securedNetwork: SecuredNetworkRepository
    let credentialsRepository: CredentialsRepository
    let ipRepository: IPRepository
    let localDB: LocalDatabase
    let appReviewManager: AppReviewManaging
    let customSoundPlaybackManager: CustomSoundPlaybackManaging
    let privacyStateManager: PrivacyStateManaging

    private var connectionTaskPublisher: AnyCancellable?
    private var gettingIpAddress = false
    private var loadLatencyValuesOnDisconnect = false
    private var currentNetwork: AppNetwork?
    private var currentWifiAutoSecured = false
    private var currentConnectionType: ConnectionType = .user

    init(logger: FileLogger,
         apiManager: APIManager,
         vpnManager: VPNManager,
         locationsManager: LocationsManagerType,
         protocolManager: ProtocolManagerType,
         preferences: Preferences,
         connectivity: Connectivity,
         wifiManager: WifiManager,
         securedNetwork: SecuredNetworkRepository,
         credentialsRepository: CredentialsRepository,
         ipRepository: IPRepository,
         localDB: LocalDatabase,
         customSoundPlaybackManager: CustomSoundPlaybackManaging,
         privacyStateManager: PrivacyStateManaging) {
        self.logger = logger
        self.apiManager = apiManager
        self.vpnManager = vpnManager
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
        self.preferences = preferences
        self.connectivity = connectivity
        self.wifiManager = wifiManager
        self.securedNetwork = securedNetwork
        self.ipRepository = ipRepository
        self.credentialsRepository = credentialsRepository
        self.localDB = localDB
        self.customSoundPlaybackManager = customSoundPlaybackManager
        self.privacyStateManager = privacyStateManager

        appReviewManager = AppReviewManager(preferences: preferences, localDatabase: localDB, logger: logger)

        vpnManager.vpnInfo.subscribe(onNext: { [weak self] vpnInfo in
            self?.combineVpnInfo.send(vpnInfo)
        }).disposed(by: disposeBag)
        
        vpnManager.getStatus().subscribe(onNext: { state in
            self.updateState(with: ConnectionState.state(from: state))
            self.saveDataForWidget()
        }).disposed(by: disposeBag)
        
        Publishers.CombineLatest(combineVpnInfo, protocolManager.currentProtocolSubject)
            .sink { [weak self] (info, nextProtocol) in
                guard let self = self else { return }
                if info == nil && nextProtocol == nil {
                    self.selectedProtoPort.onNext(protocolManager.getProtocol())
                } else if let info = info, [.connected, .connecting].contains(info.status) {
                    self.selectedProtoPort.onNext(ProtocolPort(info.selectedProtocol, info.selectedPort))
                } else if let nextProtocol = nextProtocol {
                    self.selectedProtoPort.onNext(nextProtocol)
                }
            }
            .store(in: &cancellables)

        protocolManager.connectionProtocolSubject
            .sink { [weak self] value in
                guard let self = self, let value = value else { return }
                // Only block if actually connected, not just matching protocol
                if let info = try? vpnManager.vpnInfo.value(),
                   info.selectedProtocol == value.protocolPort.protocolName,
                   info.status == .connected {
                    return
                }
                self.enableConnection(connectionType: value.connectionType)
            }
            .store(in: &cancellables)

        locationsManager.selectedLocationUpdatedSubject.subscribe { canReconnect in
            let locationID = locationsManager.getLastSelectedLocation()
            if canReconnect, !locationID.isEmpty, locationID != "0", self.isConnected() {
                self.enableConnection()
            }
            self.selectedLocationUpdatedSubject.onNext(())
        }.disposed(by: disposeBag)

        connectivity.network
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { network in
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
            }, onError: { _ in }).disposed(by: disposeBag)

        localDB.getNetworks()
            .subscribe(onNext: {
                guard let matchingNetwork = $0.first(where: { network in
                    network.isInvalidated == false && network.SSID == self.currentNetwork?.name
                }) else { return }
                if matchingNetwork.status == true, !self.currentWifiAutoSecured {
                    if self.isConnected() || self.isConnecting() {
                        self.disableConnection()
                    }
                }
                self.currentWifiAutoSecured = matchingNetwork.status
            }).disposed(by: disposeBag)

        appReviewManager.reviewRequestTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reviewRequestTrigger.onNext(())
            }
            .store(in: &cancellables)
    }
}

extension ConnectionViewModel {
    func updateLoadLatencyValuesOnDisconnect(with value: Bool) {
        loadLatencyValuesOnDisconnect = value
    }

    func isConnected() -> Bool {
        (try? connectedState.value())?.state == .connected
    }

    func isConnecting() -> Bool {
        (try? connectedState.value())?.state == .connecting
    }

    func isDisconnected() -> Bool {
        (try? connectedState.value())?.state == .disconnected
    }

    func isDisconnecting() -> Bool {
        (try? connectedState.value())?.state == .disconnecting
    }

    func isInvalid() -> Bool {
        (try? connectedState.value())?.state == .invalid
    }

    func isCustomConfigSelected() -> Bool {
        locationsManager.isCustomConfigSelected()
    }

    func isNetworkCellularWhileConnecting(for network: WifiNetwork?) -> Bool {
        if isConnecting() && network?.SSID == "Cellular" { return true }
        if isConnecting() || isConnected() {
            if let appNetwork = try? connectivity.network.value() {
                return appNetwork.networkType == NetworkType.none
            }
            return network?.SSID.uppercased() == TextsAsset.NetworkSecurity.unknownNetwork.uppercased()
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
        return locationsManager.getBestLocation() == locationsManager.getLastSelectedLocation()
    }

    func saveLastSelectedLocation(with locationID: String) {
        locationsManager.saveLastSelectedLocation(with: locationID)
    }

    func saveBestLocation(with locationID: String) {
        locationsManager.saveBestLocation(with: locationID)
    }

    func selectBestLocation(with locationID: String) {
        locationsManager.selectBestLocation(with: locationID)
    }

    func getBestLocationId() -> String {
        return locationsManager.getBestLocation()
    }

    func getBestLocation() -> BestLocationModel? {
        let bestLocationId = getBestLocationId()
        return locationsManager.getBestLocationModel(from: bestLocationId)
    }

    func getLocationType() -> LocationType? {
        return locationsManager.getLocationType()
    }

    func refreshProtocols() {
        Task { @MainActor in
            wifiManager.saveCurrentWifiNetworks()
            guard securedNetwork.getCurrentNetwork()?.preferredProtocolStatus == true else { return }
            await protocolManager.refreshProtocols(shouldReset: true,
                                                   shouldReconnect: isConnected())
        }
    }

    private func refreshConnectionFromNetworkChange() {
        if let info = try? vpnManager.vpnInfo.value() {
            if connectivity.getNetwork().name == nil || connectivity.getNetwork().name == "Unknown" {
                return
            }

            let network = localDB.getNetworksSync()?.filter {$0.SSID == connectivity.getNetwork().name}.first
            if .connected == info.status {
                wifiManager.saveCurrentWifiNetworks()
                if network?.preferredProtocol == info.selectedProtocol  && network?.preferredPort == info.selectedPort {
                    return
                }
                connectionTaskPublisher?.cancel()
                connectionTaskPublisher = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
                    .sink { _ in
                        Task { @MainActor in
                            await self.protocolManager.refreshProtocols(shouldReset: true,
                                                                        shouldReconnect: true)
                        }
                    } receiveValue: { _ in }
            } else if .connecting != info.status {
                Task { @MainActor in
                    await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                }
            }
        }
    }

    func displayLocalIPAddress() {
        if !gettingIpAddress && !isConnecting() {
            logger.logD("ConnectionViewModel", "Displaying local IP Address.")
            gettingIpAddress = true
            ipRepository.getIp().subscribe(onSuccess: { _ in
                self.gettingIpAddress = false
            }, onFailure: { _ in
                self.gettingIpAddress = false
            }).disposed(by: disposeBag)
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
            guard !WifiManager.shared.isConnectedWifiTrusted() else {
                logger.logI("ConnectionViewModel", "User joining untrusted network")

                let currentNetwork = securedNetwork.getCurrentNetwork()
                vpnManager.untrustedOneTimeOnlySSID = currentNetwork?.SSID ?? ""
                vpnManager.simpleEnableConnection()
                return
            }

            if checkCanPlayDisconnectedSound() {
                playSound(for: .disconnected)
            }

            let nextProtocol = protocolManager.getProtocol()
            let locationID = locationsManager.getLastSelectedLocation()
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
                            self.checkAutoModeFail()
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
        guard !WifiManager.shared.isConnectedWifiTrusted() else {
            logger.logI("ConnectionViewModel", "User leaving untrusted network")
            vpnManager.untrustedOneTimeOnlySSID = ""
            vpnManager.simpleDisableConnection()
            return
        }

        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    self.logger.logD("ConnectionViewModel", "Finished disabling connection.")
                    self.displayLocalIPAddress()
                    Task { @MainActor in
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
            } receiveValue: { state in
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
        loadLatencyValuesSubject.onNext(LoadLatencyInfo(force: false, connectToBestLocation: true))
    }

    private func checkShouldShowPreferredProtocol() {
        guard currentConnectionType == .failover else { return }

        let network = localDB.getNetworksSync()?.first { $0.SSID == connectivity.getNetwork().name }
        guard let network = network else { return }

        let nextProtocol = protocolManager.getProtocol()
        guard !network.preferredProtocolStatus ||
                nextProtocol.protocolName != network.preferredProtocol else {
            return
        }

        showPreferredProtocolView.onNext(nextProtocol.protocolName)
    }

    private func checkPreferencesForTriggers() {
        let connectionCount = preferences.getConnectionCount()

        if connectionCount == 2 {
            logger.logD("ConnectionViewModel", "Displaying push notifications permission popup to user.")
            pushNotificationPermissionsTrigger.onNext(())
        }
        if connectionCount == 5 {
            logger.logD("ConnectionViewModel", "Displaying Siri shortcut popup.")
            siriShortcutTrigger.onNext(())
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let count = connectionCount, count % 3 == 0 else {
                logger.logD("ConnectionViewModel", "Rate Dialog: Connection count is not a multiple of 3. Skipping...")
                return
            }

            let activeSession = self.localDB.getSessionSync()
            self.appReviewManager.requestReviewIfAvailable(session: activeSession)
        }
    }

    // This should only be called when VPN is disconnected
    private func updateToLocalIPAddress() {
        logger.logD("ConnectionViewModel", "Displaying local IP Address.")
        gettingIpAddress = true
        ipRepository.getIp().subscribe(onSuccess: { _ in
            self.gettingIpAddress = false
        }, onFailure: { _ in
            self.gettingIpAddress = false
        }).disposed(by: disposeBag)
    }

    private func saveDataForWidget() {
        let locationInfo = locationsManager.getLocationUIInfo()

        preferences.saveServerNameKey(key: locationInfo.cityName)
        preferences.saveNickNameKey(key: locationInfo.nickName)
        preferences.saveCountryCodeKey(key: locationInfo.countryCode)

        if credentialsRepository.selectedServerCredentialsType() == IKEv2ServerCredentials.self {
            preferences.setServerCredentialTypeKey(typeKey: TextsAsset.iKEv2)
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
                .invalidLocationType,
                .customConfigSupportNotAvailable,
                .noValidNodeFound,
                .invalidServerConfig,
                .configNotFound,
                .incorrectVPNManager,
                .connectionTimeout:
            return false
        case .accountExpired:
            showUpgradeRequiredTrigger.onNext(())
        case .accountBanned:
            return true
        case .locationNotFound(let id):
            reloadLocationsTrigger.onNext(id)
        case .networkIsOffline:
            showNoConnectionAlertTrigger.onNext(())
        case .upgradeRequired:
            showUpgradeRequiredTrigger.onNext(())
        case .privacyNotAccepted:
            showPrivacyTrigger.onNext(())
        case .authFailure:
            showAuthFailureTrigger.onNext(())
        case .connectivityTestFailed:
            guard locationsManager.getLocationType() == .custom else { return false }
            showAuthFailureTrigger.onNext(())
        case let .customConfigMissingCredentials(customConfig):
            showEditCustomConfigTrigger.onNext(customConfig)
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

        var canPlaySound = true
        if let currentState = try? connectedState.value() {
            canPlaySound = currentState.state != state
        }
        if canPlaySound {
            playSound(for: state)
        }

        connectedState.onNext(ConnectionStateInfo(state: state,
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
        guard let currentState = try? connectedState.value() else {
            return false
        }
        return currentState.state == .connected
    }

    private func playSound(for state: ConnectionState) {
        if state == .connected {
            customSoundPlaybackManager.playSound(for: .connect)
        } else if state == .disconnected {
            customSoundPlaybackManager.playSound(for: .disconnect)
        } else if state == .connecting {
            customSoundPlaybackManager.playSound(for: .connect, isConnecting: true)
        }
    }
}

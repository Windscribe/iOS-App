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
    var showAutoModeScreenTrigger: PublishSubject<Void> { get }
    var openNetworkHateUsDialogTrigger: PublishSubject<Void> { get }
    var trustedNetworkPopupTrigger: PublishSubject<Void> { get }
    var pushNotificationPermissionsTrigger: PublishSubject<Void> { get }
    var siriShortcutTrigger: PublishSubject<Void> { get }
    var requestLocationTrigger: PublishSubject<Void> { get }
    var showEditCustomConfigTrigger: PublishSubject<CustomConfigModel> { get }
    var reloadLocationsTrigger: PublishSubject<String> { get }
    var reviewRequestTrigger: PublishSubject<Void> { get }

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

    // Info
    func getSelectedCountryCode() -> String
    func getSelectedCountryInfo() -> LocationUIInfo
    func isBestLocationSelected() -> Bool
    func isCustomConfigSelected() -> Bool
    func getBestLocationId() -> String
    func getBestLocation() -> BestLocationModel?
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
    let showAutoModeScreenTrigger = PublishSubject<Void>()
    let openNetworkHateUsDialogTrigger = PublishSubject<Void>()
    let trustedNetworkPopupTrigger = PublishSubject<Void>()
    let pushNotificationPermissionsTrigger = PublishSubject<Void>()
    let siriShortcutTrigger = PublishSubject<Void>()
    let requestLocationTrigger = PublishSubject<Void>()
    let showEditCustomConfigTrigger = PublishSubject<CustomConfigModel>()
    let showNoConnectionAlertTrigger = PublishSubject<Void>()
    let reloadLocationsTrigger = PublishSubject<String>()
    let reviewRequestTrigger = PublishSubject<Void>()

    private let disposeBag = DisposeBag()
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

    private var connectionTaskPublisher: AnyCancellable?
    private var gettingIpAddress = false
    private var loadLatencyValuesOnDisconnect = false
    private var currentNetwork: AppNetwork?
    private var currentWifiAutoSecured = false

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
         localDB: LocalDatabase) {
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
        appReviewManager = AppReviewManager(preferences: preferences, localDatabase: localDB, logger: logger)

        vpnManager.getStatus().subscribe(onNext: { state in
            self.updateState(with: ConnectionState.state(from: state))
            self.saveDataForWidget()
        }).disposed(by: disposeBag)

        Observable.combineLatest(vpnManager.vpnInfo, protocolManager.currentProtocolSubject)
            .bind { [weak self] (info, nextProtocol) in
                guard let self = self else { return }
                if info == nil && nextProtocol == nil {
                    self.selectedProtoPort.onNext(protocolManager.getProtocol())
                } else if let info = info, [.connected, .connecting].contains(info.status) {
                    self.selectedProtoPort.onNext(ProtocolPort(info.selectedProtocol, info.selectedPort))
                } else if let nextProtocol = nextProtocol {
                    self.selectedProtoPort.onNext(nextProtocol)
                }
            }.disposed(by: disposeBag)

        protocolManager.connectionProtocolSubject
            .subscribe { [weak self] value in
                guard let self = self, let value = value else { return }
                if let info = try? vpnManager.vpnInfo.value(),
                   info.selectedProtocol == value.protocolPort.protocolName,
                   [.connected, .connecting].contains(info.status) {
                    return
                }
                self.enableConnection(connectionType: value.connectionType)
            }.disposed(by: disposeBag)

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
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.reviewRequestTrigger.onNext(())
            })
            .disposed(by: disposeBag)
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
            logger.logD(self, "Displaying local IP Address.")
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
                trustedNetworkPopupTrigger.onNext(())
                return
            }

            let nextProtocol = protocolManager.getProtocol()
            let locationID = locationsManager.getLastSelectedLocation()
            connectionTaskPublisher?.cancel()
            connectionTaskPublisher = vpnManager.connectFromViewModel(locationId: locationID, proto: nextProtocol, connectionType: connectionType)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.logger.logD(self, "Finished enabling connection.")
                    case let .failure(error):
                        if let error = error as? NEVPNError {
                            self.logger.logD(self, "NEVPNError: \(error.code)")
                            return
                        }
                        if let error = error as? VPNConfigurationErrors {
                            self.logger.logD(self, "Enable connection had a VPNConfigurationErrors:")
                            if !self.handleErrors(error: error, fromEnable: true) {
                                self.checkAutoModeFail()
                            }
                        } else {
                            self.logger.logE(self, "Enable Connection with unknown error: \(error.localizedDescription)")
                            self.checkAutoModeFail()
                        }
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        self.logger.logD(self, "Enable connection had an update: \(message)")
                    case .validated:
                        self.logger.logD(self, "Enable connection validate")
                        self.updateState(with: .connected)
                        self.checkPreferencesForTriggers()
                    case let .vpn(status):
                        self.logger.logD(self, "Enable connection new status: \(status.rawValue)")
                    case .validating:
                        self.updateState(with: .testing)
                    }
                })
        }
    }

    func disableConnection() {
        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    self.logger.logD(self, "Finished disabling connection.")
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
                        self.logger.logD(self, "Disable connection had a VPNConfigurationErrors:")
                        _ = !self.handleErrors(error: error)
                    } else {
                        self.logger.logE(self, "Disable Connection with unknown error: \(error.localizedDescription)")
                    }
                }
            } receiveValue: { state in
                switch state {
                case let .update(message):
                    self.logger.logD(self, "Disable connection had an update: \(message)")
                case let .vpn(status):
                    self.logger.logD(self, "Disable connection new status: \(status.rawValue)")
                default: ()
                }
            }
    }

    @objc private func loadLatencyValues() {
        loadLatencyValuesSubject.onNext(LoadLatencyInfo(force: false, connectToBestLocation: true))
    }

    private func checkPreferencesForTriggers() {
        let connectionCount = preferences.getConnectionCount()

        if connectionCount == 2 {
            logger.logD(self, "Displaying push notifications permission popup to user.")
            pushNotificationPermissionsTrigger.onNext(())
        }
        if connectionCount == 5 {
            logger.logD(self, "Displaying Siri shortcut popup.")
            siriShortcutTrigger.onNext(())
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let count = connectionCount, count % 3 == 0 else {
                logger.logD(self, "Rate Dialog: Connection count is not a multiple of 3. Skipping...")
                return
            }

            let activeSession = self.localDB.getSessionSync()
            self.appReviewManager.requestReviewIfAvailable(session: activeSession)
        }
    }

    // This should only be called when VPN is disconnected
    private func updateToLocalIPAddress() {
        logger.logD(self, "Displaying local IP Address.")
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
            logger.logE(self, error.description)
            return false
        case .accountExpired:
            showUpgradeRequiredTrigger.onNext(())
        case .accountBanned:
            logger.logE(self, error.description)
        case .locationNotFound(let id):
            reloadLocationsTrigger.onNext(id)
        case .networkIsOffline:
            showNoConnectionAlertTrigger.onNext(())
        case .allProtocolFailed:
            showAutoModeScreenTrigger.onNext(())
        case .upgradeRequired:
            showUpgradeRequiredTrigger.onNext(())
        case .privacyNotAccepted:
            showPrivacyTrigger.onNext(())
        case .authFailure:
            showAuthFailureTrigger.onNext(())
        case .connectivityTestFailed:
            guard locationsManager.getLocationType() == .custom else {
                logger.logE(self, error.description)
                return false
            }
            showAuthFailureTrigger.onNext(())
        case let .customConfigMissingCredentials(customConfig):
            showEditCustomConfigTrigger.onNext(customConfig)
        }
        return true
    }

    func checkAutoModeFail() {
        Task {
            let allProtocolsFailed = await protocolManager.onProtocolFail()
            if allProtocolsFailed {
                openNetworkHateUsDialogTrigger.onNext(())
            } else {
                showAutoModeScreenTrigger.onNext(())
            }
        }
    }

    func updateState(with state: ConnectionState) {
        if !gettingIpAddress, state == .disconnected, !isDisconnected() {
            displayLocalIPAddress()
        }

        connectedState.onNext(ConnectionStateInfo(state: state,
                                                  isCustomConfigSelected: self.locationsManager.isCustomConfigSelected(),
                                                  internetConnectionAvailable: false,
                                                  connectedWifi: nil))
    }
}

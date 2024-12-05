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

protocol ConnectionViewModelType {
    var connectedState: BehaviorSubject<ConnectionStateInfo> { get }
    var selectedProtoPort: BehaviorSubject<ProtocolPort?> { get }
    var selectedLocationUpdatedSubject: BehaviorSubject<Void> { get }
    
    var showUpgradeRequiredTrigger: PublishSubject<Void> { get }
    var showPrivacyTrigger: PublishSubject<Void> { get }
    var showConnectionFailedTrigger: PublishSubject<Void> { get }
    var ipAddressSubject: PublishSubject<String> { get }
    var showAutoModeScreenTrigger: PublishSubject<Void> { get }
    var openNetworkHateUsDialogTrigger: PublishSubject<Void> { get }
    var pushNotificationPermissionsTrigger: PublishSubject<Void> { get }
    var siriShortcutTrigger: PublishSubject<Void> { get }
    var requestLocationTrigger: PublishSubject<Void> { get }

    var vpnManager: VPNManager { get }

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

    // Info
    func getSelectedCountryCode() -> String
    func getSelectedCountryInfo() -> (countryCode: String, nickName: String, cityName: String)
    func isBestLocationSelected() -> Bool
    func getBestLocationId() -> String
    func getBestLocation() -> BestLocationModel?
}

class ConnectionViewModel: ConnectionViewModelType {
    let connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())
    let selectedProtoPort = BehaviorSubject<ProtocolPort?>(value: nil)
    var selectedLocationUpdatedSubject: BehaviorSubject<Void>
    
    let showUpgradeRequiredTrigger = PublishSubject<Void>()
    let showPrivacyTrigger = PublishSubject<Void>()
    let showConnectionFailedTrigger = PublishSubject<Void>()
    let ipAddressSubject = PublishSubject<String>()
    let showAutoModeScreenTrigger = PublishSubject<Void>()
    let openNetworkHateUsDialogTrigger = PublishSubject<Void>()
    let pushNotificationPermissionsTrigger = PublishSubject<Void>()
    let siriShortcutTrigger = PublishSubject<Void>()
    let requestLocationTrigger = PublishSubject<Void>()

    private let disposeBag = DisposeBag()
    let vpnManager: VPNManager
    let logger: FileLogger
    let apiManager: APIManager
    let locationsManager: LocationsManagerType
    let connectionManager: ConnectionManagerV2
    let preferences: Preferences

    private var connectionTaskPublisher: AnyCancellable?
    private var gettingIpAddress = false

    init(logger: FileLogger, apiManager: APIManager, vpnManager: VPNManager, locationsManager: LocationsManagerType, connectionManager : ConnectionManagerV2, preferences: Preferences) {
        self.logger = logger
        self.apiManager = apiManager
        self.vpnManager = vpnManager
        self.locationsManager = locationsManager
        self.connectionManager = connectionManager
        self.preferences = preferences
        selectedLocationUpdatedSubject = locationsManager.selectedLocationUpdatedSubject

        vpnManager.getStatus().subscribe(onNext: { state in
            self.connectedState.onNext(
                ConnectionStateInfo(state: ConnectionState.state(from: state),
                                    isCustomConfigSelected: false,
                                    internetConnectionAvailable: false,
                                    connectedWifi: nil))
        }).disposed(by: disposeBag)

        Observable.combineLatest(vpnManager.vpnInfo, connectionManager.currentProtocolSubject)
            .bind { [weak self] (info, nextProtocol) in
                guard let self = self else { return }
                if info == nil && nextProtocol == nil {
                    self.selectedProtoPort.onNext(connectionManager.getProtocol())
                } else if let info = info, [.connected, .connecting].contains(info.status) {
                    self.selectedProtoPort.onNext(ProtocolPort(info.selectedProtocol, info.selectedPort))
                } else if let nextProtocol = nextProtocol {
                    self.selectedProtoPort.onNext(nextProtocol)
                }
            }.disposed(by: disposeBag)

        connectionManager.connectionProtocolSubject.subscribe(onNext: { connectionProtocol in
            guard connectionProtocol != nil else { return }
            self.enableConnection()
        }).disposed(by: disposeBag)
    }
}

extension ConnectionViewModel {
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

    func setOutOfData() {
        if isConnected(), !vpnManager.isCustomConfigSelected() {
            disableConnection()
        }
    }

    func getSelectedCountryCode() -> String {
        return getSelectedCountryInfo().countryCode
    }

    func getSelectedCountryInfo() -> (countryCode: String, nickName: String, cityName: String) {
        guard let location = try? locationsManager.getLocation(from: locationsManager.getLastSelectedLocation()) else { return (countryCode: "", nickName: "", cityName: "") }
        return (countryCode: location.0.countryCode, nickName: location.1.nick, cityName: location.1.city)
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
        Task {
            await connectionManager.refreshProtocols(shouldReset: true, shouldUpdate: true, shouldReconnect: true)
        }
    }

    func enableConnection() {
        Task { @MainActor in
            checkPreferencesForTriggers()
            let nextProtocol = connectionManager.getProtocol()
            let locationID = locationsManager.getLastSelectedLocation()
            connectionTaskPublisher?.cancel()
            connectionTaskPublisher = vpnManager.connectFromViewModel(locationId: locationID, proto: nextProtocol)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.logger.logD(self, "Finished enabling connection.")
                    case let .failure(error):
                        if let error = error as? VPNConfigurationErrors {
                            self.logger.logD(self, "Enable connection had a VPNConfigurationErrors:")
                            self.handleErrors(error: error, fromEnable: true)
                        } else {
                            self.showConnectionFailedTrigger.onNext(())
                            self.logger.logE(self, "Enable Connection with unknown error: \(error.localizedDescription)")
                        }
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        self.logger.logD(self, "Enable connection had an update: \(message)")
                    case let .validated(ip):
                        self.logger.logD(self, "Enable connection validate IP: \(ip)")
                        self.ipAddressSubject.onNext(ip)
                    case let .vpn(status):
                        self.logger.logD(self, "Enable connection new status: \(status.rawValue)")
                    default:
                        break
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
                    self.updateLocalIPAddress()
                case let .failure(error):
                    if let error = error as? VPNConfigurationErrors {
                        self.logger.logD(self, "Disable connection had a VPNConfigurationErrors:")
                        self.handleErrors(error: error)
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

    private func updateLocalIPAddress() {
        logger.logD(self, "Displaying local IP Address.")
        gettingIpAddress = true
        apiManager.getIp().observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { myIp in
            self.gettingIpAddress = false
            if self.isDisconnected() {
                self.ipAddressSubject.onNext(myIp.userIp)
            }
        }, onFailure: { _ in
            self.gettingIpAddress = false
        }).disposed(by: disposeBag)
    }
    
    private func checkPreferencesForTriggers() {
        if preferences.getConnectionCount() == 1 {
            logger.logD(self, "Displaying push notifications permission popup to user.")
            pushNotificationPermissionsTrigger.onNext(())
        }
        if preferences.getConnectionCount() == 5 {
            logger.logD(self, "Displaying Siri shortcut popup.")
            siriShortcutTrigger.onNext(())
        }
    }
}

extension ConnectionViewModel {
    func handleErrors(error: VPNConfigurationErrors, fromEnable: Bool = false) {
        switch error {
        case .credentialsNotFound,
                .invalidLocationType,
                .customConfigSupportNotAvailable,
                .locationNotFound,
                .noValidNodeFound,
                .invalidServerConfig,
                .configNotFound,
                .incorrectVPNManager,
                .connectivityTestFailed,
                .authFailure,
                .networkIsOffline:
            if fromEnable {showConnectionFailedTrigger.onNext(()) }
            logger.logE(self, error.description)
        case .connectionTimeout :
            openNetworkHateUsDialogTrigger.onNext(())
        case .allProtocolFailed:
            showAutoModeScreenTrigger.onNext(())
        case .upgradeRequired:
            showUpgradeRequiredTrigger.onNext(())
        case .privacyNotAccepted:
            showPrivacyTrigger.onNext(())
        }
    }
}

extension ConnectionViewModel: VPNManagerDelegate {
    func displaySetPrefferedProtocol() {
        if let connectedWifi = WifiManager.shared.getConnectedNetwork() {
            if vpnManager.successfullProtocolChange == true && connectedWifi.preferredProtocolStatus == false {
                vpnManager.successfullProtocolChange = false
                requestLocationTrigger.onNext(())
            }
        }
    }
    
    func saveDataForWidget() {
//        if let cityName = self.vpnManager.selectedNode?.cityName, let nickName = self.vpnManager.selectedNode?.nickName, let countryCode = self.vpnManager.selectedNode?.countryCode {
//            preferences.saveServerNameKey(key: cityName)
//            preferences.saveNickNameKey(key: nickName)
//            preferences.saveCountryCodeKey(key: countryCode)
//
//            if credentialsRepo.selectedServerCredentialsType() == IKEv2ServerCredentials.self {
//                preferences.setServerCredentialTypeKey(typeKey: TextsAsset.iKEv2)
//            } else {
//                preferences.setServerCredentialTypeKey(typeKey: TextsAsset.openVPN)
//            }
//        }
//        #if os(iOS)
//        if #available(iOS 14.0, *) {
//            #if arch(arm64) || arch(i386) || arch(x86_64)
//            WidgetCenter.shared.reloadAllTimelines()
//            #endif
//        }
//        #endif
    }
}

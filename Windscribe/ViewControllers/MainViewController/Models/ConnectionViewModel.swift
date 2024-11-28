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
    var showUpgradeRequiredTrigger: PublishSubject<Void> { get }
    var showPrivacyTrigger: PublishSubject<Void> { get }
    var showConnectionFailedTrigger: PublishSubject<Void> { get }
    var ipAddressSubject: PublishSubject<String> { get }
    var selectedLocationUpdatedSubject: BehaviorSubject<Void> { get }

    var vpnManager: VPNManager { get }

    // Check State
    func isConnected() -> Bool
    func isConnecting() -> Bool
    func isDisconnected() -> Bool
    func isDisconnecting() -> Bool
    func isInvalid() -> Bool

    // Actions
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
    let showUpgradeRequiredTrigger = PublishSubject<Void>()
    let showPrivacyTrigger = PublishSubject<Void>()
    let showConnectionFailedTrigger = PublishSubject<Void>()
    let ipAddressSubject = PublishSubject<String>()
    var selectedLocationUpdatedSubject: BehaviorSubject<Void>

    private let disposeBag = DisposeBag()
    let vpnManager: VPNManager
    let logger: FileLogger
    let apiManager: APIManager
    let preferences: Preferences
    let locationsManager: LocationsManagerType

    private var connectionTaskPublisher: AnyCancellable?
    private var gettingIpAddress = false

    init(logger: FileLogger, apiManager: APIManager, vpnManager: VPNManager, preferences: Preferences, locationsManager: LocationsManagerType) {
        self.logger = logger
        self.apiManager = apiManager
        self.vpnManager = vpnManager
        self.preferences = preferences
        self.locationsManager = locationsManager
        selectedLocationUpdatedSubject = locationsManager.selectedLocationUpdatedSubject

        vpnManager.getStatus().subscribe(onNext: { state in
            self.connectedState.onNext(
                ConnectionStateInfo(state: ConnectionState.state(from: state),
                                    isCustomConfigSelected: false,
                                    internetConnectionAvailable: false,
                                    connectedWifi: nil))
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
        return preferences.getBestLocation()
    }

    func getBestLocation() -> BestLocationModel? {
        let bestLocationId = getBestLocationId()
        return locationsManager.getBestLocationModel(from: bestLocationId)
    }

    func enableConnection() {
        Task { @MainActor in
            let protocolPort = await vpnManager.getProtocolPort()
            let locationID = locationsManager.getLastSelectedLocation()
            connectionTaskPublisher?.cancel()
            connectionTaskPublisher = vpnManager.connectFromViewModel(locationId: locationID, proto: protocolPort)
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
                .connectionTimeout,
                .connectivityTestFailed,
                .allProtocolFailed,
                .authFailure,
                .networkIsOffline:
            if fromEnable {showConnectionFailedTrigger.onNext(()) }
            logger.logE(self, error.description)
        case .upgradeRequired:
            showUpgradeRequiredTrigger.onNext(())
        case .privacyNotAccepted:
            showPrivacyTrigger.onNext(())
        }
    }
}

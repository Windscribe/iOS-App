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
    var showUpgradeRequiredTrigger: PublishSubject<Void> { get }
    var showPrivacyTrigger: PublishSubject<Void> { get }

    var vpnManager: VPNManager { get }

    // Check State
    func isConnected() -> Bool
    func isConnecting() -> Bool
    func isDisconnected() -> Bool
    func isDisconnecting() -> Bool

    // Actions
    func setOutOfData()
    func enableConnection()
    func disableConnection()

    //Info
    func getSelectedCountryCode() -> String
    func isBestLocationSelected() -> Bool
}

class ConnectionViewModel: ConnectionViewModelType {
    let connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())
    let showUpgradeRequiredTrigger = PublishSubject<Void>()
    let showPrivacyTrigger = PublishSubject<Void>()

    private let disposeBag = DisposeBag()
    let vpnManager: VPNManager
    let logger: FileLogger

    private var connectionTaskPublisher: AnyCancellable?

    init(logger: FileLogger, vpnManager: VPNManager) {
        self.logger = logger
        self.vpnManager = vpnManager
        vpnManager.vpnInfo.subscribe(onNext: { vpnInfo in
            guard let vpnInfo = vpnInfo else { return }
            self.connectedState.onNext(
                ConnectionStateInfo(state: ConnectionState.state(from: vpnInfo.status),
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

    func setOutOfData() {
        if isConnected(), !vpnManager.isCustomConfigSelected() {
            disableConnection()
        }
    }

    func getSelectedCountryCode() -> String {
        vpnManager.getLocationNode()?.countryCode ?? ""
    }

    func isBestLocationSelected() -> Bool {
        return vpnManager.getLocationNode()?.cityName == Fields.Values.bestLocation
    }

    func enableConnection() {
        Task {
            let protocolPort = await vpnManager.getProtocolPort()
            let locationID = vpnManager.getLocationId()
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
                            self.handleErrors(error: error)
                        } else {
                            self.logger.logE(self, "Enable Connection with unknown error: \(error.localizedDescription)")
                        }
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        self.logger.logD(self, "Enable connection had an update: \(message)")
                    case let .validated(ip):
                        self.logger.logD(self, "Enable connection validate IP: \(ip)")
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
}

extension ConnectionViewModel {
    func handleErrors(error: VPNConfigurationErrors) {
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
            logger.logE(self, error.description)
        case .upgradeRequired:
            showUpgradeRequiredTrigger.onNext(())
        case .privacyNotAccepted:
            showPrivacyTrigger.onNext(())
        }
    }
}

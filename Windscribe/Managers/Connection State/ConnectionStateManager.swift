//
//  ConnectionStateManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
#if canImport(WidgetKit)
    import WidgetKit
#endif
import Swinject

protocol ConnectionStateManagerType {
    var connectedState: BehaviorSubject<ConnectionStateInfo> { get }

    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func checkConnectedState()
    func isConnected() -> Bool
    func isDisconnected() -> Bool
}

class ConnectionStateManager: ConnectionStateManagerType {
    var gettingIpAddress = false
    var ipAddressTimer: Timer?
    var disconnectingStateTimer: Timer?

    var connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())

    var vpnManager: VPNManager
    var logger: FileLogger
    var securedNetwork: SecuredNetworkRepository
    var localDatabase: LocalDatabase
    var apiManager: APIManager
    var latencyRepository: LatencyRepository
    let disposeBag = DisposeBag()

    private lazy var preferences: Preferences = Assembler.resolve(Preferences.self)

    private lazy var credentialsRepo: CredentialsRepository = Assembler.resolve(CredentialsRepository.self)

    private lazy var connectivity: Connectivity = Assembler.resolve(Connectivity.self)

    init(apiManager: APIManager,
         vpnManager: VPNManager,
         securedNetwork: SecuredNetworkRepository,
         localDatabase: LocalDatabase,
         latencyRepository: LatencyRepository,
         logger: FileLogger)
    {
        self.apiManager = apiManager
        self.vpnManager = vpnManager
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        self.latencyRepository = latencyRepository
        self.logger = logger
        self.vpnManager.delegate = self
    }

    @objc func displayLocalIPAddress() {
        displayLocalIPAddress(force: false)
    }

    func displayLocalIPAddress(force: Bool = false) {
        if !gettingIpAddress && !isConnecting() {
            logger.logD(self, "Displaying local IP Address.")
            gettingIpAddress = true
            apiManager.getIp().observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { myIp in
                self.gettingIpAddress = false
                if self.vpnManager.isDisconnected() || force {
                    self.vpnManager.ipAddressBeforeConnection = myIp.userIp
                }
            }, onFailure: { _ in
                self.gettingIpAddress = false
            }).disposed(by: disposeBag)
        }
    }

    func checkConnectedState() {
        if vpnManager.isConnecting() {
            logger.logD(self, "Displaying connection state \(!connectivity.internetConnectionAvailable() ? TextsAsset.disconnect : TextsAsset.connecting)")

            updateStateInfo(to: !connectivity.internetConnectionAvailable() ? .disconnected : .connecting)
            return
        }
        if vpnManager.connectivityTestTimer?.isValid ?? false {
            updateStateInfo(to: .test)
            return
        }
        let state = ConnectionState.state(from: vpnManager.connectionStatus())
        if state == .connecting, !connectivity.internetConnectionAvailable() {
            if connectivity.getNetwork().isVPN {
                logger.logD(self, "Ignoring no internet state during connection \(connectivity.getNetwork()) ")
                return
            }
            logger.logD(self, "Updating connection state to \(ConnectionState.disconnected.statusText)")
            updateStateInfo(to: .disconnected)
            return
        }
        logger.logD(self, "Displaying connection state \(state.statusText)")
        updateStateInfo(to: state)
    }

    func isConnecting() -> Bool {
        getCurrentState().state == .connecting
    }

    func isConnected() -> Bool {
        getCurrentState().state == .connected
    }

    func isDisconnected() -> Bool {
        getCurrentState().state == .disconnected
    }

}

extension ConnectionStateManager: VPNManagerDelegate {
    func saveDataForWidget() {
        DispatchQueue.main.async {
            if self.credentialsRepo.selectedServerCredentialsType() == IKEv2ServerCredentials.self {
                self.preferences.setServerCredentialTypeKey(typeKey: TextsAsset.iKEv2)
            } else {
                self.preferences.setServerCredentialTypeKey(typeKey: TextsAsset.openVPN)
            }
            #if os(iOS)
                if #available(iOS 14.0, *) {
                    #if arch(arm64) || arch(i386) || arch(x86_64)
                        WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }
            #endif
        }
    }
}

// MARK: - Private Methods
extension ConnectionStateManager {
    private func isOnDemandRetry() -> Bool {
        if vpnManager.isOnDemandRetry == true {
            updateStateInfo(to: .connected)
            return true
        }
        return false
    }
    
    private func updateStateInfo(to state: ConnectionState) {
        DispatchQueue.main.async {
            let info = ConnectionStateInfo(state: state,
                                           isCustomConfigSelected: self.vpnManager.isCustomConfigSelected(),
                                           internetConnectionAvailable: !self.connectivity.internetConnectionAvailable(),
                                           connectedWifi: self.securedNetwork.getCurrentNetwork())
            self.logger.logD(self, "Updated connection state to  \(info.state.statusText)")

            self.connectedState.onNext(info)
        }
    }

    private func getCurrentState() -> ConnectionStateInfo {
        return (try? connectedState.value()) ?? ConnectionStateInfo.defaultValue()
    }
}

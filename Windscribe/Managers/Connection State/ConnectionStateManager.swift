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
    var selectedNodeSubject: PublishSubject<SelectedNode> {get}
    var loadLatencyValuesSubject: PublishSubject<LoadLatencyInfo> {get}
    var showAutoModeScreenTrigger: PublishSubject<Void> {get}
    var openNetworkHateUsDialogTrigger: PublishSubject<Void> {get}
    var pushNotificationPermissionsTrigger: PublishSubject<Void> {get}
    var siriShortcutTrigger: PublishSubject<Void> {get}
    var requestLocationTrigger: PublishSubject<Void> {get}
    var enableConnectTrigger: PublishSubject<Void> {get}
    var ipAddressSubject: PublishSubject<String> {get}
    var autoModeSelectorHiddenChecker: PublishSubject<(_ value: Bool) -> Void> {get}
    var connectedState: BehaviorSubject<ConnectionStateInfo> {get}

    func disconnect()
    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func checkConnectedState()
    func setConnecting()
    func isConnecting() -> Bool
    func updateLoadLatencyValuesOnDisconnect(with value: Bool)
}

class ConnectionStateManager: ConnectionStateManagerType {
    var loadLatencyValuesOnDisconnect = false
    var gettingIpAddress = false
    var ipAddressTimer: Timer?
    var disconnectingStateTimer: Timer?

    var connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())
    var selectedNodeSubject = PublishSubject<SelectedNode>()
    var loadLatencyValuesSubject = PublishSubject<LoadLatencyInfo>()
    var showAutoModeScreenTrigger = PublishSubject<Void>()
    var openNetworkHateUsDialogTrigger = PublishSubject<Void>()
    var pushNotificationPermissionsTrigger = PublishSubject<Void>()
    var siriShortcutTrigger = PublishSubject<Void>()
    var requestLocationTrigger = PublishSubject<Void>()
    var enableConnectTrigger = PublishSubject<Void>()
    var ipAddressSubject = PublishSubject<String>()
    var autoModeSelectorHiddenChecker = PublishSubject<(_ value: Bool) -> Void>()

    var vpnManager: VPNManager
    var logger: FileLogger
    var securedNetwork: SecuredNetworkRepository
    var localDatabase: LocalDatabase
    var apiManager: APIManager
    var latencyRepository: LatencyRepository
    let disposeBag = DisposeBag()

    private lazy var preferences: Preferences = {
        return Assembler.resolve(Preferences.self)
    }()
    private lazy var credentialsRepo: CredentialsRepository = {
        return Assembler.resolve(CredentialsRepository.self)
    }()
    private lazy var connectivity: Connectivity = {
        return Assembler.resolve(Connectivity.self)
    }()

    init(apiManager: APIManager,
         vpnManager: VPNManager,
         securedNetwork: SecuredNetworkRepository,
         localDatabase: LocalDatabase,
         latencyRepository: LatencyRepository,
         logger: FileLogger) {
        self.apiManager = apiManager
        self.vpnManager = vpnManager
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        self.latencyRepository = latencyRepository
        self.logger = logger
        self.vpnManager.delegate = self
    }

    func disconnect() {
        ConnectionManager.shared.onConnectStateChange(state: .disconnected)
        vpnManager.successfullProtocolChange = false
        if ConnectionManager.shared.goodProtocol != nil {
            // saving timestamp to reset good Protocol after 12 hours
            ConnectionManager.shared.resetGoodProtocolTime = Date()
            ConnectionManager.shared.scheduleTimer()
        }
        vpnManager.userTappedToDisconnect = true
        vpnManager.connectIntent = false
        vpnManager.resetProfiles {
            self.setDisconnected()
            self.vpnManager.resetProperties()
            self.vpnManager.isFromProtocolFailover = false
            self.vpnManager.isFromProtocolChange = false
            self.enableConnectTrigger.onNext(())
        }
    }

    @objc func displayLocalIPAddress() {
        displayLocalIPAddress(force: false)
    }

    func displayLocalIPAddress(force: Bool = false) {
        if !self.gettingIpAddress && !isConnecting() {
            logger.logD(self, "Displaying local IP Address.")
            self.gettingIpAddress = true
            apiManager.getIp().observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { myIp in
                self.gettingIpAddress = false
                if self.vpnManager.isDisconnected() || force {
                    self.vpnManager.ipAddressBeforeConnection = myIp.userIp
                    self.ipAddressSubject.onNext(myIp.userIp)
                }
            }, onFailure: { _ in
                self.gettingIpAddress = false
            }).disposed(by: disposeBag)
        }
    }

    func checkConnectedState() {
        if case .connecting = vpnManager.connectionStatus() {
            logger.logD(self, "Displaying connection state \(!connectivity.internetConnectionAvailable() ? TextsAsset.disconnect : TextsAsset.connecting)")

            updateStateInfo(to: !connectivity.internetConnectionAvailable() ? .disconnected : .connecting)
            return
        }
        if vpnManager.connectivityTestTimer?.isValid ?? false {
            updateStateInfo(to: .test)
            return
        }
        if let state = ConnectionState.state(from: vpnManager.connectionStatus()) {
            if state == .connecting, !connectivity.internetConnectionAvailable() {
                if connectivity.getNetwork().isVPN {
                    logger.logD(self, "Ignoring no internet state during connection \(connectivity.getNetwork()) ")
                    return
                }
                logger.logD(self, "Updating connection state to \( ConnectionState.disconnected.statusText)")
                updateStateInfo(to: .disconnected)
                return
            }
            logger.logD(self, "Displaying connection state \(state.statusText)")
            updateStateInfo(to: state)
        }
    }

    func isConnecting() -> Bool {
        getCurrentState().state == .connecting
    }

    func updateLoadLatencyValuesOnDisconnect(with value: Bool) {
        loadLatencyValuesOnDisconnect = value
    }
}

extension ConnectionStateManager: VPNManagerDelegate {
    func selectedNodeChanged() {
        setLastConnected()
        setConnectionLabelValuesForSelectedNode()
    }

    func setDisconnected() {
        saveDataForWidget()
        if  vpnManager.connectionStatus() == .connected {
            logger.logD(self, "Ignoring disconnection if vpn is connected \(vpnManager.connectionStatus())")
            return
        }
        if loadLatencyValuesOnDisconnect {
            updateStateInfo(to: .disconnected)
            setConnectionLabelValuesForSelectedNode()
            loadLatencyValuesOnDisconnect = false
            Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(loadLatencyValues), userInfo: nil, repeats: false)
            return
        } else {
            updateStateInfo(to: .disconnected)
            ipAddressTimer?.invalidate()
            ipAddressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.displayLocalIPAddress), userInfo: nil, repeats: false)
        }
    }

    func setDisconnecting() {
        updateStateInfo(to: .disconnecting)
        if self.vpnManager.userTappedToDisconnect { return }
        disconnectingStateTimer?.invalidate()
        disconnectingStateTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(setDisconnectingStateIfStillDisconnecting), userInfo: nil, repeats: false)
    }

    func setConnectivityTest() {
        guard !isOnDemandRetry(), !vpnManager.userTappedToDisconnect else { return }
        updateStateInfo(to: .test)
    }

    func setConnected(ipAddress: String) {
        guard !isOnDemandRetry(), !vpnManager.userTappedToDisconnect else { return }
        updateStateInfo(to: .connected)
        ipAddressSubject.onNext(ipAddress)
        if preferences.getConnectionCount() == 2 {
            logger.logD(self, "Displaying push notifications permission popup to user.")
            pushNotificationPermissionsTrigger.onNext(())
        }
        if preferences.getConnectionCount() == 5 {
            logger.logD(self, "Displaying Siri shortcut popup.")
            siriShortcutTrigger.onNext(())
        }
        saveDataForWidget()
    }

    func setConnecting() {
        guard !isOnDemandRetry() else { return }
#if os(tvOS)
        self.updateStateInfo(to: .connecting)
#endif
        autoModeSelectorHiddenChecker.onNext {
            if $0 { self.updateStateInfo(to: .connecting) }
        }
    }

    func setAutomaticModeFailed() {
        self.updateStateInfo(to: .automaticFailed)
        showAutoModeScreenTrigger.onNext(())
    }

    func showAutomaticModeFailedToConnectPopup() {
        logger.logD(self, "Auto Mode couldn't find any protocol/port working.")
        openNetworkHateUsDialogTrigger.onNext(())
    }

    func saveDataForWidget() {
        if let cityName = self.vpnManager.selectedNode?.cityName, let nickName = self.vpnManager.selectedNode?.nickName, let countryCode = self.vpnManager.selectedNode?.countryCode {
            preferences.saveServerNameKey(key: cityName)
            preferences.saveNickNameKey(key: nickName)
            preferences.saveCountryCodeKey(key: countryCode)

            if credentialsRepo.selectedServerCredentialsType() == IKEv2ServerCredentials.self {
                preferences.setServerCredentialTypeKey(typeKey: TextsAsset.iKEv2)
            } else {
                preferences.setServerCredentialTypeKey(typeKey: TextsAsset.openVPN)
            }
        }
        #if os(iOS)
        if #available(iOS 14.0, *) {
            #if arch(arm64) || arch(i386) || arch(x86_64)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
        #endif
    }

    func displaySetPrefferedProtocol() {
        if let connectedWifi = WifiManager.shared.getConnectedNetwork() {
            if self.vpnManager.successfullProtocolChange == true && connectedWifi.preferredProtocolStatus == false {
                self.vpnManager.successfullProtocolChange = false
                requestLocationTrigger.onNext(())
            }
        }
    }

    func disconnectVpn() {
        self.disconnect()
    }
}

// MARK: - Private Methods
extension ConnectionStateManager {
    private func isOnDemandRetry() -> Bool {
        if self.vpnManager.isOnDemandRetry == true {
            updateStateInfo(to: .connected)
            return true
        }
        return false
    }

    private func setLastConnected() {
        guard let selectedNode = vpnManager.selectedNode else { return }
        let lastConnectedNode = LastConnectedNode(selectedNode: selectedNode)
        localDatabase.saveLastConnectedNode(node: lastConnectedNode).disposed(by: disposeBag)
    }

    private func setConnectionLabelValuesForSelectedNode() {
        guard let selectedNode = self.vpnManager.selectedNode else { return }
        selectedNodeSubject.onNext(selectedNode)
    }

    @objc private func loadLatencyValues() {
        loadLatencyValuesSubject.onNext(LoadLatencyInfo(force: false, selectBestLocation: true, connectToBestLocation: true))
    }

    @objc private func setDisconnectingStateIfStillDisconnecting() {
        if self.vpnManager.isDisconnecting() {
           checkConnectedState()
        }
    }

    private func updateStateInfo(to state: ConnectionState) {
        let info = ConnectionStateInfo(state: state,
                                       isCustomConfigSelected: vpnManager.isCustomConfigSelected(),
                                       internetConnectionAvailable: !connectivity.internetConnectionAvailable(),
                                       customConfig: vpnManager.selectedNode?.customConfig,
                                       connectedWifi: securedNetwork.getCurrentNetwork())
        connectedState.onNext(info)
    }

    private func getCurrentState() -> ConnectionStateInfo {
        return (try? connectedState.value()) ?? ConnectionStateInfo.defaultValue()
    }
}

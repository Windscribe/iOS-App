//
//  VPNManager+ConnectionStatus.swift
//  Windscribe
//
//  Created by Thomas on 10/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
#if canImport(WidgetKit)
    import RxSwift
    import WidgetKit
#endif

extension VPNManager {
    func isConnectedToVpn() -> Bool {
        if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
           let scopes = settings["__SCOPED__"] as? [String: Any]
        {
            for (key, _) in scopes {
                if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") {
                    return true
                }
            }
        }
        return false
    }

    func isConnected() -> Bool {
        for manager in configManager.managers {
            if manager.connection.status == .connected && manager.protocolConfiguration?.username != nil {
                return true
            }
        }
        return false
    }

    func isConnecting() -> Bool {
        for manager in configManager.managers {
            if manager.connection.status == .connecting && manager.protocolConfiguration?.username != nil {
                return true
            }
        }
        return false
    }

    func isDisconnected() -> Bool {
        for manager in configManager.managers {
            if manager.connection.status == .disconnected && manager.protocolConfiguration?.username != nil {
                return true
            }
        }
        return false
    }

    func isDisconnecting() -> Bool {
        for manager in configManager.managers where manager.connection.status == .disconnecting {
            return true
        }
        return false
    }

    func isInvalid() -> Bool {
        if credentialsRepository.selectedServerCredentialsType().self == IKEv2ServerCredentials.self && configManager.iKEV2Manager()?.connection.status != .invalid {
            return false
        }
        if credentialsRepository.selectedServerCredentialsType().self == OpenVPNServerCredentials.self && configManager.openVPNdManager()?.connection.status != .invalid {
            return false
        }
        return true
    }

    func isDisconnectedAndNotConfigured() -> Bool {
        return isDisconnected() || (!configManager.isConfigured(manager: configManager.iKEV2Manager()) && !configManager.isConfigured(manager: configManager.openVPNdManager()))
    }

    func checkIfUserIsOutOfData() {
        DispatchQueue.main.async {
            guard let session = self.sessionManager.session else { return }
            if session.status == 2, !self.isCustomConfigSelected() {
                VPNManager.shared.disconnectAllVPNConnections(setDisconnect: true)
            }
        }
    }

    func setTimeoutForConnectingState() {
        connectingTimer?.invalidate()
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            logger.logI(VPNManager.self, "App is in background.")
            return
        }
        if credentialsRepository.selectedServerCredentialsType().self == IKEv2ServerCredentials.self {
            connectingTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(disconnectIfStillConnecting), userInfo: nil, repeats: false)
        } else {
            connectingTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(disconnectIfStillConnecting), userInfo: nil, repeats: false)
        }
    }

    func connectionStatus() -> NEVPNStatus {
        var status = NEVPNStatus.disconnected
        configManager.managers.forEach {
            if $0.protocolConfiguration?.username != nil {
                status = $0.connection.status
            }
        }
        return status
    }

    func checkForForceDisconnect() {
        if let hostname = selectedNode?.hostname {
            let group = localDB.getServers()?.flatMap { $0.groups }.filter { $0.bestNodeHostname == hostname }.first
            if group?.bestNode?.forceDisconnect ?? false {
                logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] force_disconnect found on \(hostname)")
                selectAnotherNode()
                if isConnected() {
                    configureAndConnectVPN()
                }
            }
        }
    }

    func isCustomConfigSelected() -> Bool {
        return VPNManager.shared.selectedNode?.customConfig != nil
    }

    @objc func connectionStatusChanged(_: Notification?) {
        configureForConnectionState()
        #if os(iOS)
            if #available(iOS 14.0, *) {
                #if arch(arm64) || arch(i386) || arch(x86_64)
                    WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        #endif
    }

    func configureForConnectionState() {
        DispatchQueue.main.async {
            self.delegate?.saveDataForWidget()
        }
        let state = UIApplication.shared.applicationState
        getVPNConnectionInfo(completion: { [self] info in
            guard let info = info else {
                return
            }
            self.vpnInfo.onNext(info)
            let inactive = state == .background || state == .inactive
            if inactive {
                return
            }
            let connectionStatus = info.status
            let protocolType = info.selectedProtocol
            if self.lastConnectionStatus == connectionStatus { return }
            let active = state == .background || state == .inactive
            self.logger.logI(VPNManager.self, "Updated connection Info: \(info.description)")
            self.lastConnectionStatus = connectionStatus
            return
                configManager.invalidateTimer()
            switch connectionStatus {
            case .connecting:
                self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] [\(protocolType)] VPN Status: Connecting")
                WSNet.instance().setIsConnectedToVpnState(false)
                self.delegate?.saveDataForWidget()
                self.delegate?.setConnecting()
                self.checkIfUserIsOutOfData()
                self.setTimeoutForConnectingState()
                VPNManager.shared.triedToConnect = true
            case .connected:
                self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] [\(protocolType)] VPN Status: Connected")
                WSNet.instance().setIsConnectedToVpnState(true)
                VPNManager.shared.untrustedOneTimeOnlySSID = ""
                VPNManager.shared.triedToConnect = true
                self.disconnectCounter = 0
                self.delegate?.saveDataForWidget()
                self.delegate?.setConnectivityTest()
                self.contentIntentTimer?.invalidate()
                self.connectingTimer?.invalidate()
                self.connectivityTestTimer?.invalidate()
                self.connectivityTestTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.runConnectivityTestWithRetry), userInfo: nil, repeats: false)

            case .disconnecting:
                self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] [\(protocolType)] VPN Status: Disconnecting")

                WSNet.instance().setIsConnectedToVpnState(false)
                if self.forceToKeepConnectingState() { self.delegate?.setConnecting() } else { self.delegate?.setDisconnecting() }
                self.setTimeoutForDisconnectingState()
            case .disconnected:
                self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] [\(protocolType)] VPN Status: Disconnected")
                handleConnectError()
                WSNet.instance().setIsConnectedToVpnState(false)
                self.delegate?.saveDataForWidget()
                if self.forceToKeepConnectingState() { self.delegate?.setConnecting() } else { self.delegate?.setDisconnecting() }
                self.disconnectingTimer?.invalidate()
                self.checkForRetry()
                self.contentIntentTimer?.invalidate()
                self.contentIntentTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(self.checkForConnectIntent), userInfo: nil, repeats: false)
            case .invalid:
                if !self.restartOnDisconnect {
                    self.delegate?.setDisconnected()
                }
                self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] [\(protocolType)] VPN Status: Invalid")
                WSNet.instance().setIsConnectedToVpnState(false)
            case .reasserting:
                self.keepConnectingState = false
            default:
                return
            }
        })
    }

    func forceToKeepConnectingState() -> Bool {
        return (keepConnectingState || VPNManager.shared.connectIntent || retryWithNewCredentials) && connectivity.internetConnectionAvailable()
    }

    func checkForRetry() {
        if !VPNManager.shared.triedToConnect || VPNManager.shared.userTappedToDisconnect || !connectivity.internetConnectionAvailable() {
            return
        }
        disconnectCounter += 1
        if disconnectCounter > 3, !isFromProtocolFailover, !isFromProtocolChange {
            disconnectCounter = 0
            logger.logE(VPNManager.self, "Too many disconnects. Disabling VPN profile.")
            VPNManager.shared.userTappedToDisconnect = true
            resetProfiles {
                VPNManager.shared.userTappedToDisconnect = false
            }
            disconnectOrFail()
            return
        }
        if restartOnDisconnect {
            logger.logI(ConnectionManager.self, "Reconnecting..")
            restartOnDisconnect = false
            retryTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(retryConnection), userInfo: nil, repeats: false)
            return
        } else if retryWithNewCredentials, VPNManager.shared.selectedNode?.customConfig == nil, !isFromProtocolFailover, !isFromProtocolChange {
            logger.logI(ConnectionManager.self, "Trying with server credentials.")
            retryWithNewCredentials = false
            retryConnectionWithNewServerCredentials()
            return
        } else if disableOrFailOnDisconnect {
            disconnectOrFail()
            return
        }
    }

    func disconnectOrFail() {
        delegate?.setConnecting()
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            logger.logI(VPNManager.self, "App is in background.")
            return
        }
        if selectedConnectionMode != Fields.Values.auto ||
            isCustomConfigSelected()
        {
            disconnectActiveVPNConnection(setDisconnect: true)
        } else {
            disconnectActiveVPNConnection()
            retryInProgress = true
            retryTimer?.invalidate()
            delay(3) { [self] in
                ConnectionManager.shared.onProtocolFail { [self] allProtocolsFailed in
                    if allProtocolsFailed {
                        delegate?.showAutomaticModeFailedToConnectPopup()
                    } else {
                        delegate?.setAutomaticModeFailed()
                    }
                }
            }
        }
    }

    @objc func checkForConnectIntent() {
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            logger.logI(VPNManager.self, "App is in background.")
            return
        }
        if VPNManager.shared.connectIntent, !WifiManager.shared.isConnectedWifiTrusted(), connectivity.internetConnectionAvailable(), VPNManager.shared.isDisconnected(), selectedFirewallMode == true {
            logger.logE(VPNManager.self, "Connect Intent is true. Retrying to connect.")
            retryWithNewCredentials = true
            configureAndConnectVPN()
        }
    }

    func handleConnectError() {
        if awaitingConnectionCheck || preferences.getKillSwitchSync() {
            return
        }
        awaitingConnectionCheck = true
        getLastConnectionError { error in
            guard let error = error else {
                self.awaitingConnectionCheck = false
                return
            }
            if error == .credentialsFailure {
                self.logger.logD(self, "VPN disconnected due to credential failure")
                self.connectIntent = false
                self.resetProfiles {
                    self.logger.logE(self, "Disabling VPN Profiles to get access api access.")
                    delay(2) {
                        self.logger.logE(self, "Getting new session.")
                        self.api.getSession(nil).subscribe(onSuccess: { session in
                            self.logger.logE(self, "Saving updated session.")
                            DispatchQueue.main.async {
                                self.localDB.saveSession(session: session).disposed(by: self.disposeBag)
                            }
                            self.awaitingConnectionCheck = false
                        }, onFailure: { _ in
                            self.logger.logE(self, "Failure to update session after disabling VPN profile.")
                            self.awaitingConnectionCheck = false
                        }).disposed(by: self.disposeBag)
                    }
                }
            } else {
                self.awaitingConnectionCheck = false
                self.logger.logE(self, "Unhandled connection error: \(error.description)")
            }
        }
    }

    @available(iOS 16.0, tvOS 17.0, *)
    private func handleIKEv2Error(_ error: Error?, completion: @escaping (VPNErrors?) -> Void) {
        guard let error = error else {
            completion(nil)
            return
        }
        if let nsError = error as NSError?, nsError.domain == NEVPNConnectionErrorDomain {
            switch nsError.code {
            case 12, 8:
                completion(.credentialsFailure)
            default:
                logger.logD(self, "NEVPNManager error: \(error)")
                completion(nil)
            }
        } else {
            logger.logD(self, "NEVPNManager error: \(error)")
            completion(nil)
        }
    }

    @available(iOS 16.0, tvOS 17.0, *)
    private func handleNEVPNProviderError(_ error: Error?, completion: @escaping (VPNErrors?) -> Void) {
        guard let error = error as NSError? else {
            completion(nil)
            return
        }
        if error.code == 50 {
            completion(.credentialsFailure)
        } else {
            logger.logD(self, "NEVPNProvider error: \(error)")
            completion(nil)
        }
    }

    private func getLastConnectionError(completion: @escaping (VPNErrors?) -> Void) {
        guard #available(iOS 16.0, tvOS 17.0, *) else {
            completion(nil)
            return
        }

        var manager: NEVPNManager?
        if let provider = configManager.wireguardManager(), provider.protocolConfiguration?.username != nil {
            manager = provider
        } else if let provider = configManager.openVPNdManager(), provider.protocolConfiguration?.username != nil {
            manager = provider
        } else if let provider = configManager.iKEV2Manager(), provider.protocolConfiguration?.username != nil {
            manager = provider
        }

        if let manager = manager {
            manager.connection.fetchLastDisconnectError { error in
                self.handleNEVPNProviderError(error, completion: completion)
            }
        } else {
            completion(nil)
        }
    }

    private func disableOnDemandMode() {
        configManager.managers.forEach {
            if $0.protocolConfiguration?.username != nil {
                configManager.setOnDemandMode(false, for: $0)
            }
        }
    }
}

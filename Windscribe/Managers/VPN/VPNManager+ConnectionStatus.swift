//
//  VPNManager+Connection.swift
//  Windscribe
//
//  Created by Thomas on 10/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import NetworkExtension
#if canImport(WidgetKit)
import WidgetKit
import RxSwift
#endif

extension VPNManager {
    func isConnected() -> Bool {
        return (IKEv2VPNManager.shared.neVPNManager.connection.status == .connected && IKEv2VPNManager.shared.isConfigured())  || (OpenVPNManager.shared.providerManager?.connection.status == .connected && OpenVPNManager.shared.isConfigured()) ||
        (WireGuardVPNManager.shared.providerManager?.connection.status == .connected && WireGuardVPNManager.shared.isConfigured())
    }

     func isConnectedToVpn() -> Bool {
        if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
            let scopes = settings["__SCOPED__"] as? [String: Any] {
            for (key, _) in scopes {
             if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") {
                    return true
                }
            }
        }
        return false
    }

    func isConnecting() -> Bool {
        return (IKEv2VPNManager.shared.neVPNManager.connection.status == .connecting && IKEv2VPNManager.shared.isConfigured())  || (OpenVPNManager.shared.providerManager?.connection.status == .connecting && OpenVPNManager.shared.isConfigured()) ||
            (WireGuardVPNManager.shared.providerManager?.connection.status == .connecting && WireGuardVPNManager.shared.isConfigured())
    }

    func isDisconnected() -> Bool {
       return (IKEv2VPNManager.shared.neVPNManager.connection.status == .disconnected && IKEv2VPNManager.shared.isConfigured())  || (OpenVPNManager.shared.providerManager?.connection.status == .disconnected && OpenVPNManager.shared.isConfigured()) || (WireGuardVPNManager.shared.providerManager?.connection.status == .disconnected && WireGuardVPNManager.shared.isConfigured())
    }

    func isDisconnecting() -> Bool {
        return IKEv2VPNManager.shared.neVPNManager.connection.status == .disconnecting ||  OpenVPNManager.shared.providerManager?.connection.status == .disconnecting ||  WireGuardVPNManager.shared.providerManager?.connection.status == .disconnecting
    }

    func isInvalid() -> Bool {
        if credentialsRepository.selectedServerCredentialsType().self == IKEv2ServerCredentials.self && IKEv2VPNManager.shared.neVPNManager.connection.status != .invalid {
            return false
        }
        if credentialsRepository.selectedServerCredentialsType().self == OpenVPNManager.self &&  OpenVPNManager.shared.providerManager?.connection.status != .invalid {
            return false
        }
        return true
    }

    func checkIfUserIsOutOfData() {
        guard let session = sessionManager.session else { return }
        if session.status == 2 && !isCustomConfigSelected() {
            VPNManager.shared.disconnectAllVPNConnections(setDisconnect: true)
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
        var status = IKEv2VPNManager.shared.neVPNManager.connection.status
        if OpenVPNManager.shared.isConfigured() {
            status = OpenVPNManager.shared.providerManager?.connection.status ?? .disconnected
        }
        if WireGuardVPNManager.shared.isConfigured() {
            status = WireGuardVPNManager.shared.providerManager?.connection.status ?? .disconnected
        }
        return status
    }

    func checkForForceDisconnect() {
        logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Checking for force_disconnect")
        if let hostname = selectedNode?.hostname {
           let group = localDB.getServers()?.flatMap({ $0.groups }).filter({ $0.bestNodeHostname == hostname }).first
            if group?.bestNode?.forceDisconnect ?? false {
                logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] force_disconnect found on \(hostname)")
                self.selectAnotherNode()
                if self.isConnected() {
                    self.configureAndConnectVPN()
                }
            }
        }
    }

    func isCustomConfigSelected() -> Bool {
        return VPNManager.shared.selectedNode?.customConfig != nil
    }

    @objc func connectionStatusChanged(_ notification: Notification?) {
        self.configureForConnectionState()
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
            if state == .background || state == .inactive {
                self.logger.logI(VPNManager.self, "App is in background. connection info is \(info.description)")
                return
            }
            let connectionStatus = info.status
            print("#### VPN Status is \(connectionStatus)")
            let protocolType = info.selectedProtocol
            if self.lastConnectionStatus == connectionStatus { return }
            self.lastConnectionStatus = connectionStatus
            IKEv2VPNManager.shared.noResponseTimer?.invalidate()
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
        return (keepConnectingState || VPNManager.shared.connectIntent || self.retryWithNewCredentials) && connectivity.internetConnectionAvailable()
    }

    func checkForRetry() {
        if !VPNManager.shared.triedToConnect || VPNManager.shared.userTappedToDisconnect || !connectivity.internetConnectionAvailable() {
            return
        }
        disconnectCounter += 1
        if disconnectCounter > 3 && !isFromProtocolFailover && !isFromProtocolChange {
            disconnectCounter = 0
            self.logger.logE(VPNManager.self, "Too many disconnects. Disabling VPN profile.")
            VPNManager.shared.userTappedToDisconnect = true
            self.resetProfiles {
                VPNManager.shared.userTappedToDisconnect = false
            }
            self.disconnectOrFail()
            return
        }
        if restartOnDisconnect {
            self.logger.logI(ConnectionManager.self, "Reconnecting..")
            self.restartOnDisconnect = false
            self.retryTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.retryConnection), userInfo: nil, repeats: false)
            return
        } else if retryWithNewCredentials && VPNManager.shared.selectedNode?.customConfig == nil && !isFromProtocolFailover && !isFromProtocolChange {
            self.logger.logI(ConnectionManager.self, "Trying with server credentials.")
            self.retryWithNewCredentials = false
            self.retryConnectionWithNewServerCredentials()
            return
        } else if disableOrFailOnDisconnect {
            self.disconnectOrFail()
            return
        }
    }

    func disconnectOrFail() {
        self.delegate?.setConnecting()
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            self.logger.logI(VPNManager.self, "App is in background.")
            return
        }
        if self.selectedConnectionMode != Fields.Values.auto ||
            self.isCustomConfigSelected() {
            self.disconnectActiveVPNConnection(setDisconnect: true)
        } else {
            self.disconnectActiveVPNConnection()
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
            self.logger.logI(VPNManager.self, "App is in background.")
            return
        }
        if VPNManager.shared.connectIntent && !WifiManager.shared.isConnectedWifiTrusted() && connectivity.internetConnectionAvailable() && VPNManager.shared.isDisconnected() && self.selectedFirewallMode == true {
            logger.logE(VPNManager.self, "Connect Intent is true. Retrying to connect.")
            self.retryWithNewCredentials = true
            self.configureAndConnectVPN()
        }
    }

    private func handleConnectError() {
        self.logger.logD(self, "Getting last connection error.")
        getLastConnectionError { error in
            guard let error = error else {
                self.logger.logD(self, "No last connection error found")
                return
            }
            if error == .credentialsFailure {
                self.logger.logD(self, "Disconnecting due to auth failure.")
                self.connectIntent = false
                self.disableOnDemandMode()
                self.logger.logE(self, "Getting new session.")
                self.api.getSession(nil).subscribe(onSuccess: { session in
                    self.logger.logE(self, "Received updated session: \(session).")
                    DispatchQueue.main.async {
                        self.localDB.saveSession(session: session).disposed(by: self.disposeBag)
                    }
                },onFailure: { _ in
                    self.logger.logE(self, "Failure to update session.")
                }).disposed(by: self.disposeBag)
            } else {
                self.logger.logD(self, "Last VPN Error: \(error.description)")
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
                self.logger.logD(self, "NEVPNManager error: \(error)")
                completion(nil)
            }
        } else {
            self.logger.logD(self, "NEVPNManager error: \(error)")
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
            self.logger.logD(self, "NEVPNProvider error: \(error)")
            completion(nil)
        }
    }

    private func getLastConnectionError(completion: @escaping (VPNErrors?) -> Void) {
        guard #available(iOS 16.0, tvOS 17.0, *) else {
            completion(nil)
            return
        }
        if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.providerManager.connection.fetchLastDisconnectError { error in
                self.handleNEVPNProviderError(error, completion: completion)
            }
        } else if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.providerManager.connection.fetchLastDisconnectError { error in
                self.handleNEVPNProviderError(error, completion: completion)
            }
        } else if IKEv2VPNManager.shared.isConfigured() {
            IKEv2VPNManager.shared.neVPNManager.connection.fetchLastDisconnectError { error in
                self.handleIKEv2Error(error, completion: completion)
            }
        } else {
            completion(nil)
        }
    }

    private func disableOnDemandMode() {
        if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.setOnDemandMode(false)
        } else if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.setOnDemandMode(false)
        } else if IKEv2VPNManager.shared.isConfigured() {
            IKEv2VPNManager.shared.setOnDemandMode(false)
        }
    }
}

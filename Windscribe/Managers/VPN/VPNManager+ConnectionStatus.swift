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
        (try? vpnInfo.value())?.status == .connected
    }

    func isConnecting() -> Bool {
        (try? vpnInfo.value())?.status == .connecting
    }

    func isDisconnected() -> Bool {
        (try? vpnInfo.value())?.status == .disconnected
    }

    func isDisconnecting() -> Bool {
        (try? vpnInfo.value())?.status == .disconnecting
    }

    func isInvalid() -> Bool {
        (try? vpnInfo.value())?.status == .invalid
    }

    func isDisconnectedAndNotConfigured() -> Bool {
        return isDisconnected() || (!configManager.isConfigured(manager: configManager.iKEV2Manager()) && !configManager.isConfigured(manager: configManager.openVPNdManager()))
    }

    func checkIfUserIsOutOfData() {
        DispatchQueue.main.async {
            guard let session = self.sessionManager.session else { return }
            if session.status == 2, !self.isCustomConfigSelected() {
                self.disconnectAllVPNConnections(setDisconnect: true)
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
        return (try? vpnInfo.value()?.status) ?? NEVPNStatus.disconnected
    }

    func isCustomConfigSelected() -> Bool {
        // TODO: VPNManager Check if custom Config is used
//        return selectedNode?.customConfig != nil
        return false
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
            self.getVPNConnectionInfo(completion: { [self] info in
                guard let info = info else {
                    return
                }
                self.vpnInfo.onNext(info)
                let connectionStatus = info.status
                let protocolType = info.selectedProtocol
                if self.lastConnectionStatus == connectionStatus { return }
                self.logger.logI("VPNConfiguration", "Updated connection Info: \(info.description)")
                self.lastConnectionStatus = connectionStatus
                self.delegate?.saveDataForWidget()
                switch connectionStatus {
                case .connecting:
                    self.logger.logD(VPNManager.self, "[\(uniqueConnectionId)] [\(protocolType)] VPN Status: Connecting")
                    WSNet.instance().setIsConnectedToVpnState(false)
                    self.checkIfUserIsOutOfData()
                case .connected:
                    self.logger.logD(VPNManager.self, "[\(uniqueConnectionId)] [\(protocolType)] VPN Status: Connected")
                    WSNet.instance().setIsConnectedToVpnState(true)
                    untrustedOneTimeOnlySSID = ""
                    triedToConnect = true
                case .disconnecting:
                    self.logger.logD(VPNManager.self, "[\(uniqueConnectionId)] [\(protocolType)] VPN Status: Disconnecting")
                    WSNet.instance().setIsConnectedToVpnState(false)
                case .disconnected:
                    self.logger.logD(VPNManager.self, "[\(uniqueConnectionId)] [\(protocolType)] VPN Status: Disconnected")
                    handleConnectError()
                    WSNet.instance().setIsConnectedToVpnState(false)
                case .invalid:
                    self.logger.logD(VPNManager.self, "[\(uniqueConnectionId)] [\(protocolType)] VPN Status: Invalid")
                    WSNet.instance().setIsConnectedToVpnState(false)
                case .reasserting:
                    self.keepConnectingState = false
                default:
                    return
                }
            })
        }
    }

    func forceToKeepConnectingState() -> Bool {
        return (keepConnectingState || connectIntent || retryWithNewCredentials) && connectivity.internetConnectionAvailable()
    }

    @objc func checkForConnectIntent() {
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            logger.logI(VPNManager.self, "App is in background.")
            return
        }
        if connectIntent, !WifiManager.shared.isConnectedWifiTrusted(), connectivity.internetConnectionAvailable(), isDisconnected(), selectedFirewallMode == true {
            logger.logI(VPNManager.self, "Connect Intent is true. Retrying to connect.")
            retryWithNewCredentials = true
            configureAndConnectVPN()
        }
    }

    func handleConnectError() {
        if awaitingConnectionCheck {
            return
        }
        awaitingConnectionCheck = true
        getLastConnectionError { error in
            guard let error = error else {
                self.awaitingConnectionCheck = false
                return
            }
            if error == .credentialsFailure {
                AlertManager.shared.showSimpleAlert(title: TextsAsset.error, message: "VPN will be disconnected due to credential failure", buttonText: TextsAsset.okay)
                self.logger.logD(self, "VPN disconnected due to credential failure")
                self.connectIntent = false
                self.resetProfiles {
                    self.logger.logI(self, "Disabling VPN Profiles to get access api access.")
                    delay(2) {
                        self.logger.logI(self, "Getting new session.")
                        self.api.getSession(nil).subscribe(onSuccess: { session in
                            self.logger.logI(self, "Saving updated session.")
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
        for manager in configManager.managers {
            if manager.protocolConfiguration?.username != nil {
                configManager.setOnDemandMode(false, for: manager)
            }
        }
    }
}

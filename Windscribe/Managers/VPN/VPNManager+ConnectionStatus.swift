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

    func checkIfUserIsOutOfData() {
        DispatchQueue.main.async {
            guard let session = self.sessionManager.session else { return }
            if session.status == 2, !self.locationsManager.isCustomConfigSelected() {
                self.disconnectAllVPNConnections(setDisconnect: true)
            }
        }
    }

    func connectionStatus() -> NEVPNStatus {
        return (try? vpnInfo.value()?.status) ?? NEVPNStatus.disconnected
    }

    @objc func connectionStatusChanged(_: Notification?) {
        connectionStateUpdatedTrigger.onNext(())
    }

    func configureForConnectionState() {
        DispatchQueue.main.async {
            self.delegate?.saveDataForWidget()
            self.getVPNConnectionInfo(completion: { [self] info in
                guard let info = info else {
                    return
                }
                self.logger.logI("VPNConfiguration", "Updated connection Info: \(info.description)")
                self.vpnInfo.onNext(info)
                let connectionStatus = info.status
                let protocolType = info.selectedProtocol
                if self.lastConnectionStatus == connectionStatus { return }
                self.lastConnectionStatus = connectionStatus
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
}

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

    func connectionStatus() -> NEVPNStatus {
        return (try? vpnInfo.value()?.status) ?? NEVPNStatus.disconnected
    }

    @objc func connectionStatusChanged(_: Notification?) {
        connectionStateUpdatedTrigger.onNext(())
    }

    func configureForConnectionState() {
        DispatchQueue.main.async {
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
                    self.logger.logD(VPNManager.self, "[\(protocolType)] VPN Status: Connecting")
                    self.checkIfUserIsOutOfData()
                case .connected:
                    self.logger.logD(VPNManager.self, "[\(protocolType)] VPN Status: Connected")
                    untrustedOneTimeOnlySSID = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.updateUserIpIfRequired()
                    }
                case .disconnecting:
                    self.logger.logD(VPNManager.self, "[\(protocolType)] VPN Status: Disconnecting")
                case .disconnected:
                    self.logger.logD(VPNManager.self, "[\(protocolType)] VPN Status: Disconnected")
                    handleConnectError()
                case .invalid:
                    self.logger.logD(VPNManager.self, "[\(protocolType)] VPN Status: Invalid")
                default:
                    return
                }
            })
        }
    }

    /// If connected state was not pushed as result of app connecting (On demand mode) and we have non VPN IP,
    /// push an update.
    private func updateUserIpIfRequired() {
        // State changed from background or on demand mode.
        guard let ipState = try? ipRepository.ipState.value(), configurationState == .initial else {
            return
        }
        if ipState == .updating {
            return
        }
        switch ipState {
        case .available(let ip):
            // Ip is available but its a NON VPN IP.
            if !ip.isInvalidated && !ip.isOurIp {
                logger.logI(self, "Updating non VPN IP after connection update from on demand mode.")
                ipRepository.getIp().subscribe().disposed(by: disposeBag)
            }
        default: ()
        }
    }
}

extension VPNManager {
    private func handleConnectError() {
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
                Task {
                    await self.resetProfiles()
                    self.logger.logI(self, "Disabling VPN Profiles to get access api access.")
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    self.logger.logI(self, "Getting new session.")
                    self.sessionManager.getUppdatedSession().subscribe(onSuccess: { session in
                        self.awaitingConnectionCheck = false
                    }, onFailure: { _ in
                        self.logger.logE(self, "Failure to update session after disabling VPN profile.")
                        self.awaitingConnectionCheck = false
                    }).disposed(by: self.disposeBag)
                }
            } else {
                self.awaitingConnectionCheck = false
                self.logger.logE(self, "Unhandled connection error: \(error.description)")
            }
        }
    }

    private func checkIfUserIsOutOfData() {
        DispatchQueue.main.async {
            guard let session = self.sessionManager.session else { return }
            if session.status == 2, !self.locationsManager.isCustomConfigSelected() {
                self.simpleDisableConnection()
            }
        }
    }

    /**
     Parses updated VPN connection info from configured VPN managers.
     */
    private func getVPNConnectionInfo(completion: @escaping (VPNConnectionInfo?) -> Void) {
        // Refresh and load all VPN Managers from system preferrances.
        let priorityStates = [NEVPNStatus.connecting, NEVPNStatus.connected, NEVPNStatus.disconnecting]
        var priorityManagers: [NEVPNManager] = []
        for manager in configManager.managers {
            if priorityStates.contains(manager.connection.status) {
                priorityManagers.append(manager)
            }
        }
        if priorityManagers.count == 1 {
            if configManager.isIKEV2(manager: priorityManagers[0]) {
                completion(configManager.getIKEV2ConnectionInfo(manager: priorityManagers[0]))
            } else {
                completion(configManager.getVPNConnectionInfo(manager: priorityManagers[0]))
            }
            return
        }

        if let enabledManager = priorityManagers.filter({ $0.isEnabled }).first {
            if configManager.isIKEV2(manager: enabledManager) {
                completion(configManager.getIKEV2ConnectionInfo(manager: enabledManager))
            } else {
                completion(configManager.getVPNConnectionInfo(manager: enabledManager))
            }
            return
        }

        // No VPN Manager is configured
        if (configManager.managers.filter { $0.connection.status != .invalid }).isEmpty {
            completion(nil)
            return
        }
        // Get VPN connection info from last active manager.
        if activeVPNManager == .iKEV2 {
            completion(configManager.getIKEV2ConnectionInfo(manager: configManager.iKEV2Manager()))
        } else {
            completion(configManager.getVPNConnectionInfo(manager: configManager.getManager(for: activeVPNManager)))
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

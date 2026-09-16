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

extension VPNManagerImpl {

    @objc func connectionStatusChanged(_: Notification?) {
        vpnStateRepository.connectionStateUpdatedTrigger.send(())
    }

    func configureForConnectionState() {
        DispatchQueue.main.async {
            self.getVPNConnectionInfo(completion: { [self] info in
                guard let info = info else {
                    return
                }
                self.logger.logI("VPNConfiguration", "Updated connection Info: \(info.description)")
                self.vpnStateRepository.vpnInfo.send(info)
                let connectionStatus = info.status
                let protocolType = info.selectedProtocol
                if self.vpnStateRepository.lastConnectionStatus == connectionStatus { return }
                self.vpnStateRepository.setLastConnectionStatus(connectionStatus)

                switch connectionStatus {
                case .connecting:
                    self.logger.logI("VPNConfiguration", "[\(protocolType)] VPN Status: Connecting")
                    self.checkIfUserIsOutOfData()
                case .connected:
                    self.logger.logI("VPNConfiguration", "[\(protocolType)] VPN Status: Connected")
                    // Clear all failed servers on successful connection - fresh start for next connection attempt
                    self.configManager.clearFailedServers()
                    vpnStateRepository.setUntrustedOneTimeOnlySSID("")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.updateUserIpIfRequired()
                    }
                case .disconnecting:
                    self.logger.logI("VPNConfiguration", "[\(protocolType)] VPN Status: Disconnecting")
                case .disconnected:
                    self.logger.logI("VPNConfiguration", "[\(protocolType)] VPN Status: Disconnected")
                    handleConnectError()
                case .invalid:
                    self.logger.logI("VPNConfiguration", "[\(protocolType)] VPN Status: Invalid")
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
        guard let ipState = ipRepository.ipState.value, vpnStateRepository.configurationState == .initial else {
            return
        }
        if ipState == .updating {
            return
        }
        switch ipState {
        case .available(_):
            // Refresh IP after VPN connection from on-demand mode to display current IP
            logger.logI("VPNManager", "Refreshing IP after VPN connection from on-demand mode.")
            Task { @MainActor in
                try? await ipRepository.getIp()
            }
        default: ()
        }
    }
}

extension VPNManagerImpl {
    private func handleConnectError() {
        guard !awaitingConnectionCheck else { return }
        awaitingConnectionCheck = true
        Task { @MainActor in
            defer { awaitingConnectionCheck = false }
            guard let error = await configManager.getGeneralConnectError(),
                  case let .classified(failure) = error,
                  failure.reason == .accountSessionInvalid || failure.reason == .accountLimitation else {
                return
            }
            logger.logE("VPNManager", "VPN disconnected due to \(failure.reason).")
            sessionManager.checkForDiscconectReasonTrigger.send(())
        }
    }

    private func checkIfUserIsOutOfData() {
        DispatchQueue.main.async {
            guard let session = self.userSessionRepository.sessionModel else { return }
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
        for manager in configManager.managers where priorityStates.contains(manager.connection.status) {
            priorityManagers.append(manager)
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
}

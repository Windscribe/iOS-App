//
//  VPNManager+Selector.swift
//  Windscribe
//
//  Created by Thomas on 17/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
#if canImport(WidgetKit)
    import WidgetKit
#endif
import Combine
import RxSwift
import Swinject

extension VPNManager {
    @objc func configureAndConnectVPN() {
      // TODO: VPNManager configureAndConnectVPN
    }

    @objc func hideAskToRetryPopup() {
        displayingAskToRetryPopup?.dismiss(animated: true, completion: nil)
    }

    @objc func retryWithAutomaticMode(protocolType _: String?) {
        retryInProgress = false
    }

    @objc func retryIKEv2Connection() {
        Task {
            self.activeVPNManager = .iKEV2
            await configManager.connect(with: .iKEV2, killSwitch: killSwitch)
        }
    }

    @objc func retryOpenVPNConnection() {
        Task {
            self.activeVPNManager = .openVPN
            await configManager.connect(with: .openVPN, killSwitch: killSwitch)
        }
    }

    @objc func retryWireGuardVPNConnection() {
        Task {
            self.activeVPNManager = .wg
            await configManager.connect(with: .wg, killSwitch: killSwitch)
        }
    }

    private func resetProfiles() -> Completable {
        return Completable.create { completable in
            self.resetWireguard {
                self.resetOpenVPN {
                    self.resetIkev2 {
                        completable(.completed)
                    }
                }
            }
            return Disposables.create {}
        }
    }

    @objc func disconnectActiveVPNConnection(setDisconnect: Bool = false, disableConnectIntent: Bool = false) {
        logger.logD(VPNManager.self, "[\(uniqueConnectionId)] [\(selectedConnectionMode ?? "")] Disconnecting Active VPN connection")

        configManager.invalidateTimer()
        if selectedConnectionMode == Fields.Values.auto {
            resetProperties()
        }
        if disableConnectIntent { connectIntent = false }

        Task {
            for manager in configManager.managers {
                if manager.protocolConfiguration?.username != nil {
                    await configManager.disconnect(killSwitch: killSwitch, manager: manager)
                }
            }
        }
    }

    func disconnectIfRequired(completion: @escaping () -> Void) {
        if selectedConnectionMode == Fields.Values.auto {
            resetProperties()
        }
        if isConnected() || isConnecting() {
            logger.logD(VPNManager.self, "Reconnecting...")
            keepConnectingState = true

            Task {
                for manager in configManager.managers {
                    if manager.protocolConfiguration?.username != nil {
                        await configManager.disconnect(killSwitch: killSwitch, manager: manager)
                    }
                }
                completion()
            }
        } else {
            logger.logD(VPNManager.self, "Connecting...")
            completion()
        }
    }

    @objc func disconnectAllVPNConnections(setDisconnect: Bool = false, force _: Bool = false) {
        resetProfiles {
            if setDisconnect {
            }
        }
    }

    func resetWireguard(comletion: @escaping () -> Void) {
        Task {
            await configManager.reset(manager: configManager.wireguardManager())
            comletion()
        }
    }

    func resetOpenVPN(comletion: @escaping () -> Void) {
        Task {
            await configManager.reset(manager: configManager.openVPNdManager())
            comletion()
        }
    }

    func resetIkev2(comletion: @escaping () -> Void) {
        Task {
            await configManager.reset(manager: configManager.iKEV2Manager())
            comletion()
        }
    }

    func resetProfiles(comletion: @escaping () -> Void) {
        resetWireguard {
            self.resetOpenVPN {
                self.resetIkev2 {
                    comletion()
                }
            }
        }
    }

    @objc func disconnectAndDisable() {
        disableOrFailOnDisconnect = true
        for manager in configManager.managers {
            if manager.connection.status == .connected || manager.connection.status == .connecting {
                Task {
                    await configManager.disconnect(killSwitch: killSwitch, manager: manager)
                }
            }
        }
    }

    @objc func disconnectIfStillConnecting() {
        for manager in configManager.managers {
            if manager.connection.status == .connecting, manager.connection.status != .disconnected {
                disableOrFailOnDisconnect = true
                isOnDemandRetry = false
                Task {
                    await configManager.disconnect(killSwitch: killSwitch, manager: manager)
                    logger.logE(VPNManager.self, "[\(uniqueConnectionId)] Connecting timeout for \(configManager.getManagerName(from: manager)) connection.")
                }
            }
        }
    }

    @objc func removeVPNProfileIfStillDisconnecting() {
        getVPNConnectionInfo { info in
            guard let info = info else {
                return
            }
            if info.killSwitch || info.onDemand {
                self.logger.logI(VPNManager.self, "Kill-Switch/Firewall on unable to remove VPN Profile.")
                return
            }

            for manager in self.configManager.managers {
                if manager.connection.status == .disconnecting {
                    self.isOnDemandRetry = false
                    Task {
                        await self.configManager.disconnect(killSwitch: self.killSwitch, manager: manager)
                        await self.configManager.removeProfile(killSwitch: self.killSwitch, manager: manager)
                        self.logger.logE(VPNManager.self, "Disconnecting timeout. Removing \(self.configManager.getManagerName(from: manager)) VPN profile.")
                    }
                }
            }
        }
    }

    // function to check if local ip belongs to RFC 1918 ips
    func checkLocalIPIsRFC() -> Bool {
        if let localIPAddress = NWInterface.InterfaceType.wifi.ipv4 {
            if localIPAddress.isRFC1918IPAddress {
                logger.logD(VPNManager.self, "It's an RFC1918 address. \(localIPAddress)")
                return true
            } else {
                logger.logD(VPNManager.self, "Non Rfc-1918 address found  \(localIPAddress)")
                return false
            }
        } else {
            logger.logD(VPNManager.self, "Failed to retrieve local IP address.")
            return true
        }
    }
}

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
import Combine
import Swinject

extension VPNManagerImpl {
    func simpleEnableConnection() {
        let nextProtocol = protocolManager.getProtocol()
        let locationID = locationsManager.getLastConnectionTarget()
        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = connectFromViewModel(locationId: locationID, proto: nextProtocol, connectionType: .user)
            .sink { _ in } receiveValue: { _ in }
    }

    func simpleDisableConnection() {
        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = disconnectFromViewModel()
            .sink { _ in } receiveValue: { _ in }
    }

    func resetProfiles() async {
        for manager in configManager.managers {
            await configManager.reset(manager: manager)
        }
    }

    func removeProfiles() async {
        // Enumerate installed managers from the system — the cached wg/op managers load async and
        // are often empty at logout (#1124).
        var managers: [NEVPNManager] = []
        if let tunnels = try? await NETunnelProviderManager.loadAllFromPreferences() {
            managers.append(contentsOf: tunnels)
        }
        let ikev2 = NEVPNManager.shared()
        try? await ikev2.loadFromPreferences()
        if ikev2.protocolConfiguration != nil {
            managers.append(ikev2)
        }
        logger.logI("VPNManager", "Logout: removing \(managers.count) VPN profile(s).")
        for manager in managers {
            await disableAndRemove(manager: manager)
        }
    }

    /// Disable on-demand and save first (a modify on an approved config — prompt-free) so iOS stops
    /// auto-reconnecting, then stop the tunnel, then remove. One manager instance throughout (#1124).
    private func disableAndRemove(manager: NEVPNManager) async {
        manager.onDemandRules = []
        manager.isOnDemandEnabled = false
        manager.isEnabled = false
        #if os(iOS)
            manager.protocolConfiguration?.includeAllNetworks = false
        #endif
        try? await manager.saveToPreferences()
        if [.connected, .connecting, .reasserting].contains(manager.connection.status) {
            manager.connection.stopVPNTunnel()
        }
        await configManager.remove(manager: manager)
    }

    // function to check if local ip belongs to RFC 1918 ips
    func checkLocalIPIsRFC() -> Bool {
        if let localIPAddress = NWInterface.InterfaceType.wifi.ipv4 {
            if localIPAddress.isRFC1918IPAddress {
                logger.logD("VPNManager", "It's an RFC1918 address. \(localIPAddress.redactedIP)")
                return true
            } else {
                logger.logD("VPNManager", "Non Rfc-1918 address found  \(localIPAddress.redactedIP)")
                return false
            }
        } else {
            logger.logD("VPNManager", "Failed to retrieve local IP address.")
            return true
        }
    }
}

//
//  Preferences+WireGuard.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-09-18.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

extension PreferencesImpl {

    // WireGuard Interface Configuration
    func saveWireGuardAddress(_ address: String?) {
        setString(address, forKey: SharedKeys.address)
    }

    func getWireGuardAddress() -> String? {
        return getString(forKey: SharedKeys.address)
    }

    func saveWireGuardDNS(_ dns: String?) {
        setString(dns, forKey: SharedKeys.dns)
    }

    func getWireGuardDNS() -> String? {
        return getString(forKey: SharedKeys.dns)
    }

    // WireGuard Peer Configuration
    func saveWireGuardPresharedKey(_ key: String?) {
        setString(key, forKey: SharedKeys.preSharedKey)
    }

    func getWireGuardPresharedKey() -> String? {
        return getString(forKey: SharedKeys.preSharedKey)
    }

    func saveWireGuardAllowedIPs(_ ips: String?) {
        setString(ips, forKey: SharedKeys.allowedIp)
    }

    func getWireGuardAllowedIPs() -> String? {
        return getString(forKey: SharedKeys.allowedIp)
    }

    // WireGuard Server Configuration
    func saveWireGuardServerEndpoint(_ endpoint: String?) {
        setString(endpoint, forKey: SharedKeys.serverEndPoint)
    }

    func getWireGuardServerEndpoint() -> String? {
        return getString(forKey: SharedKeys.serverEndPoint)
    }

    func saveWireGuardServerHostname(_ hostname: String?) {
        setString(hostname, forKey: SharedKeys.serverHostName)
    }

    func getWireGuardServerHostname() -> String? {
        return getString(forKey: SharedKeys.serverHostName)
    }

    func saveWireGuardServerPublicKey(_ key: String?) {
        setString(key, forKey: SharedKeys.serverPublicKey)
    }

    func getWireGuardServerPublicKey() -> String? {
        return getString(forKey: SharedKeys.serverPublicKey)
    }

    func saveWireGuardServerPort(_ port: String?) {
        setString(port, forKey: SharedKeys.wgPort)
    }

    func getWireGuardServerPort() -> String? {
        return getString(forKey: SharedKeys.wgPort)
    }

    // WireGuard Cleanup
    func clearWireGuardConfiguration() {
        removeObjects(forKey: [
            SharedKeys.preSharedKey,
            SharedKeys.allowedIp,
            SharedKeys.dns,
            SharedKeys.address,
            SharedKeys.serverEndPoint,
            SharedKeys.serverHostName,
            SharedKeys.serverPublicKey,
            SharedKeys.wgPort
        ])
    }
}

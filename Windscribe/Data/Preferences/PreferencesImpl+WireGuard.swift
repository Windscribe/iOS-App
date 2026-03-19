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

    func saveWireGuardAllowedIPsV6(_ ips: String?) {
        setString(ips, forKey: SharedKeys.allowedIpV6)
    }

    func getWireGuardAllowedIPsV6() -> String? {
        return getString(forKey: SharedKeys.allowedIpV6)
    }

    func saveWireGuardHashedCIDR(_ cidr: [String]?) {
        sharedDefault?.setValue(cidr, forKey: SharedKeys.hashedCIDR)
    }

    func getWireGuardHashedCIDR() -> [String]? {
        return sharedDefault?.array(forKey: SharedKeys.hashedCIDR) as? [String]
    }

    func saveWireGuardHashedCIDRv6(_ cidr: [String]?) {
        sharedDefault?.setValue(cidr, forKey: SharedKeys.hashedCIDRv6)
    }

    func getWireGuardHashedCIDRv6() -> [String]? {
        return sharedDefault?.array(forKey: SharedKeys.hashedCIDRv6) as? [String]
    }

    func saveWireGuardAddressV6(_ address: String?) {
        setString(address, forKey: SharedKeys.addressV6)
    }

    func getWireGuardAddressV6() -> String? {
        return getString(forKey: SharedKeys.addressV6)
    }

    // WireGuard Server Configuration
    func saveWireGuardServerEndpoint(_ endpoint: String?) {
        setString(endpoint, forKey: SharedKeys.serverEndPoint)
    }

    func getWireGuardServerEndpoint() -> String? {
        return getString(forKey: SharedKeys.serverEndPoint)
    }

    func saveWireGuardServerSupportsIPv6(_ supports: Bool) {
        sharedDefault?.set(supports, forKey: SharedKeys.serverSupportsIPv6)
    }

    func getWireGuardServerSupportsIPv6() -> Bool {
        return sharedDefault?.bool(forKey: SharedKeys.serverSupportsIPv6) ?? false
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
            SharedKeys.allowedIpV6,
            SharedKeys.hashedCIDR,
            SharedKeys.hashedCIDRv6,
            SharedKeys.dns,
            SharedKeys.address,
            SharedKeys.addressV6,
            SharedKeys.serverSupportsIPv6,
            SharedKeys.serverEndPoint,
            SharedKeys.serverHostName,
            SharedKeys.serverPublicKey,
            SharedKeys.wgPort
        ])
    }
}

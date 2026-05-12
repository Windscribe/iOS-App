//
//  WgCredentials.swift
//  Windscribe
//
//  Created by Thomas on 09/03/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import WireGuardKit

class WgCredentials {
    var presharedKey: String?
    var allowedIps: String?
    var allowedIpsV6: String?
    var address: String?
    var addressV6: String?
    var dns: String?

    var serverEndPoint: String?
    var serverHostName: String?
    var serverSupportsIPv6: Bool = false
    var serverPublicKey: String?
    var port: String?
    var deleteOldestKey = true
    private let logger: FileLogger
    private let preferences: Preferences
    private let keychainManager: KeychainManager
    init(preferences: Preferences, logger: FileLogger, keychainManager: KeychainManager) {
        self.preferences = preferences
        self.logger = logger
        self.keychainManager = keychainManager
    }

    func load() {
        // Load state from saved
        address = preferences.getWireGuardAddress()
        addressV6 = preferences.getWireGuardAddressV6()
        presharedKey = preferences.getWireGuardPresharedKey()
        allowedIps = preferences.getWireGuardAllowedIPs()
        allowedIpsV6 = preferences.getWireGuardAllowedIPsV6()

        serverEndPoint = preferences.getWireGuardServerEndpoint()
        serverHostName = preferences.getWireGuardServerHostname()
        serverPublicKey = preferences.getWireGuardServerPublicKey()
        serverSupportsIPv6 = preferences.getWireGuardServerSupportsIPv6()
        port = preferences.getWireGuardServerPort()
        dns = preferences.getWireGuardDNS()
    }

    func getPublicKey() async -> String? {
        return await Task.detached(priority: .utility) { [weak self] in
            guard let self = self,
                  let privateKey = self.getPrivateKey() else { return nil }
            return PrivateKey(base64Key: privateKey)?.publicKey.base64Key
        }.value
    }

    // Generate private key if not available and save it to keychain.
    func getPrivateKey() -> String? {
        do {
            let currentKey = try keychainManager.getString(
                forKey: SharedKeys.privateKey,
                service: "WireguardService",
                accessGroup: SharedKeys.sharedKeychainGroup)
            return currentKey
        } catch {
            // Key doesn't exist, generate new one
            do {
                let privateKey = PrivateKey().base64Key
                try keychainManager.setString(
                    privateKey,
                    forKey: SharedKeys.privateKey,
                    service: "WireguardService",
                    accessGroup: SharedKeys.sharedKeychainGroup)
                return privateKey
            } catch {
                logger.logE("WgCredentials", "Error saving new private key to keychain: \(error)")
                return nil
            }
        }
    }

    // wg Init
    func initialized() -> Bool {
        return getWgInitResponse() != nil
    }

    func getWgInitResponse() -> DynamicWireGuardConfig? {
        presharedKey = preferences.getWireGuardPresharedKey()
        allowedIps = preferences.getWireGuardAllowedIPs()
        let hashedCIDR = preferences.getWireGuardHashedCIDR()
        // Require hashedCIDR for initialization to ensure existing users migrate to new IP generation
        if presharedKey != nil, allowedIps != nil, hashedCIDR != nil {
            let config = DynamicWireGuardConfig()
            config.presharedKey = presharedKey
            config.allowedIPs = allowedIps
            config.hashedCIDR = hashedCIDR
            config.hashedCIDRv6 = preferences.getWireGuardHashedCIDRv6()
            config.allowedIPsV6 = preferences.getWireGuardAllowedIPsV6()
            return config
        }
        return nil
    }

    func saveInitResponse(config: DynamicWireGuardConfig) {
        presharedKey = config.presharedKey
        allowedIps = config.allowedIPs
        allowedIpsV6 = config.allowedIPsV6
        preferences.saveWireGuardPresharedKey(config.presharedKey)
        preferences.saveWireGuardAllowedIPs(config.allowedIPs)
        preferences.saveWireGuardAllowedIPsV6(config.allowedIPsV6)
        preferences.saveWireGuardHashedCIDR(config.hashedCIDR)
        preferences.saveWireGuardHashedCIDRv6(config.hashedCIDRv6)
    }

    // Save locally generated IP and DNS
    func saveGeneratedIP(ip: String, dns: String, ipV6: String? = nil) {
        self.address = ip
        self.addressV6 = ipV6
        self.dns = dns
        preferences.saveWireGuardAddress(ip)
        preferences.saveWireGuardAddressV6(ipV6)
        preferences.saveWireGuardDNS(dns)
    }

    func setNodeToConnect(serverEndPoint: String, serverHostName: String, serverPublicKey: String, port: String, ipv6: Int) {
        self.serverEndPoint = serverEndPoint
        self.serverHostName = serverHostName
        self.serverPublicKey = serverPublicKey
        self.port = port
        self.serverSupportsIPv6 = ipv6 != 0
        preferences.saveWireGuardServerEndpoint(serverEndPoint)
        preferences.saveWireGuardServerHostname(serverHostName)
        preferences.saveWireGuardServerPublicKey(serverPublicKey)
        preferences.saveWireGuardServerSupportsIPv6(serverSupportsIPv6)
        preferences.saveWireGuardServerPort(port)
    }

    // Delete credentials and key if user status changes
    func delete() {
        do {
            try keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: SharedKeys.sharedKeychainGroup)
        } catch {
            logger.logE("WgCredentials", "Error deleting private key from keychain: \(error)")
        }
        dns = nil
        address = nil
        addressV6 = nil
        presharedKey = nil
        allowedIps = nil
        allowedIpsV6 = nil
        serverSupportsIPv6 = false
        preferences.clearWireGuardConfiguration()
    }

    // MARK: - IPv6 expectation helpers

    func expectsIPv6ForCurrentServer() -> Bool {
        return serverSupportsIPv6 && preferences.getEgressProtocolPreferenceSync() == "Auto"
    }

    func hasIPv6InitDataForCurrentServer() -> Bool {
        let v6Allowed = allowedIpsV6 ?? preferences.getWireGuardAllowedIPsV6()
        let v6CIDR = preferences.getWireGuardHashedCIDRv6()
        return !(v6Allowed?.isEmpty ?? true) && !(v6CIDR?.isEmpty ?? true)
    }

    func hasCompleteIPv6ConfigForCurrentServer() -> Bool {
        let hasAddressV6 = !(addressV6?.isEmpty ?? true)
        let hasAllowedV6 = !(allowedIpsV6?.isEmpty ?? true)
        let hasHashedCIDRv6 = !(preferences.getWireGuardHashedCIDRv6()?.isEmpty ?? true)
        return hasAddressV6 && hasAllowedV6 && hasHashedCIDRv6
    }

    func needsIPv6InitRefreshForCurrentServer() -> Bool {
        return expectsIPv6ForCurrentServer() && !hasIPv6InitDataForCurrentServer()
    }

    func asWgCredentialsString() -> String? {
        if let privateKey = getPrivateKey(),
           let address = address,
           let dns = dns,
           let allowedIps = allowedIps,
           let presharedKey = presharedKey,
           let serverPublicKey = serverPublicKey,
           let serverEndPoint = serverEndPoint,
           let port = port
        {
            if expectsIPv6ForCurrentServer() && !hasCompleteIPv6ConfigForCurrentServer() {
                logger.logE("WgCredentials", "IPv6 expected for current server but config is incomplete (addressV6/allowedIpsV6/hashedCIDRv6 missing); falling back to IPv4-only")
            }

            let hasAddressV6 = !(addressV6?.isEmpty ?? true)
            let hasAllowedV6 = !(allowedIpsV6?.isEmpty ?? true)
            let includeV6 = hasAddressV6 && hasAllowedV6
            let fullAddress = includeV6 ? "\(address), \(addressV6!)" : address
            let fullAllowedIps = includeV6 ? "\(allowedIps), \(allowedIpsV6!)" : allowedIps

            var lines: [String] = [
                "[Interface]",
                "PrivateKey = \(privateKey)",
                "Address = \(fullAddress)",
                "Dns = \(dns)"
            ]
            if preferences.isCircumventCensorshipEnabled() {
                let unblockParams = preferences.getUnblockWgParams()?.getConfigText() ?? []
                lines.append(contentsOf: unblockParams)
            }
            lines.append(contentsOf: [
                "",
                "[Peer]",
                "PublicKey = \(serverPublicKey)",
                "AllowedIPs = \(fullAllowedIps)",
                "Endpoint = \(serverEndPoint):\(port)",
                "PresharedKey = \(presharedKey)"
            ])
            return lines.joined(separator: "\n")
        } else {
            return nil
        }
    }

    var debugDescription: String {
        return "Endpoint: \(serverEndPoint ?? "") Hostname: \(serverHostName ?? "") Server public key: \(serverPublicKey ?? "") \n User public key: [async] Allowed Ip: \(allowedIps ?? "") Allowed IpV6: \(allowedIpsV6 ?? "") Preshared key: \(presharedKey ?? "") Address: \(address ?? "") AddressV6: \(addressV6 ?? "") Port: \(port ?? "") Dns: \(dns ?? "")"
    }
}

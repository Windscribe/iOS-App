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
    var address: String?
    var dns: String?

    var serverEndPoint: String?
    var serverHostName: String?
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
        presharedKey = preferences.getWireGuardPresharedKey()
        allowedIps = preferences.getWireGuardAllowedIPs()

        serverEndPoint = preferences.getWireGuardServerEndpoint()
        serverHostName = preferences.getWireGuardServerHostname()
        serverPublicKey = preferences.getWireGuardServerPublicKey()
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
        if presharedKey != nil, allowedIps != nil {
            let config = DynamicWireGuardConfig()
            config.presharedKey = presharedKey
            config.allowedIPs = allowedIps
            return config
        }
        return nil
    }

    func saveInitResponse(config: DynamicWireGuardConfig) {
        presharedKey = config.presharedKey
        allowedIps = config.allowedIPs
        preferences.saveWireGuardPresharedKey(config.presharedKey)
        preferences.saveWireGuardAllowedIPs(config.allowedIPs)
    }

    // wg Connect
    func saveConnectResponse(config: DynamicWireGuardConnect) {
        dns = config.dns
        address = config.address
        preferences.saveWireGuardAddress(config.address)
        preferences.saveWireGuardDNS(config.dns)
    }

    func setNodeToConnect(serverEndPoint: String, serverHostName: String, serverPublicKey: String, port: String) {
        self.serverEndPoint = serverEndPoint
        self.serverHostName = serverHostName
        self.serverPublicKey = serverPublicKey
        self.port = port
        preferences.saveWireGuardServerEndpoint(serverEndPoint)
        preferences.saveWireGuardServerHostname(serverHostName)
        preferences.saveWireGuardServerPublicKey(serverPublicKey)
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
        presharedKey = nil
        allowedIps = nil
        preferences.clearWireGuardConfiguration()
    }

    func asWgCredentialsString() -> String? {
        let udpStuffing = preferences.isCircumventCensorshipEnabled()
        if let privateKey = getPrivateKey(),
           let address = address,
           let dns = dns,
           let allowedIps = allowedIps,
           let presharedKey = presharedKey,
           let serverPublicKey = serverPublicKey,
           let serverEndPoint = serverEndPoint,
           let port = port
        {
            let lines = ["[Interface]",
                         "PrivateKey = \(privateKey)",
                         "Address = \(address)",
                         "Dns = \(dns)",
                         "",
                         "[Peer]",
                         "PublicKey = \(serverPublicKey)",
                         "AllowedIPs = \(allowedIps)",
                         "Endpoint = \(serverEndPoint):\(port)",
                         "udp_stuffing = \(udpStuffing)",
                         "PresharedKey = \(presharedKey)"]
            return lines.joined(separator: "\n")
        } else {
            return nil
        }
    }

    var debugDescription: String {
        return "Endpoint: \(serverEndPoint ?? "") Hostname: \(serverHostName ?? "") Server public key: \(serverPublicKey ?? "") \n User public key: [async] Allowed Ip: \(allowedIps ?? "") Preshared key: \(presharedKey ?? "") Address: \(address ?? "") Port: \(port ?? "") Dns: \(dns ?? "")"
    }
}

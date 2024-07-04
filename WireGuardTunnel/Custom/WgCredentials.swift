//
//  WireGuardVPNConfigs.swift
//  Windscribe
//
//  Created by Thomas on 09/03/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import JNKeychain
import WireGuardKit
import Swinject

class WgCredentials {

    var presharedKey: String?
    var allowedIps: String?
    var address: String?
    var dns: String?

    var serverEndPoint: String?
    var serverHostName: String?
    var serverPublicKey: String?
    var port: String?
    private let logger: FileLogger
    private let preferences: Preferences

    init(preferences: Preferences, logger: FileLogger) {
        self.preferences = preferences
        self.logger = logger
    }

    func load(){
        // Load state from saved
        address = SharedSecretDefaults.shared.getString(forKey: SharedKeys.address)
        presharedKey = SharedSecretDefaults.shared.getString(forKey: SharedKeys.preSharedKey)
        allowedIps = SharedSecretDefaults.shared.getString(forKey: SharedKeys.allowedIp)

        serverEndPoint = SharedSecretDefaults.shared.getString(forKey: SharedKeys.serverEndPoint)
        serverHostName = SharedSecretDefaults.shared.getString(forKey: SharedKeys.serverHostName)
        serverPublicKey = SharedSecretDefaults.shared.getString(forKey: SharedKeys.serverPublicKey)
        port = SharedSecretDefaults.shared.getString(forKey: SharedKeys.wgPort)
        dns = SharedSecretDefaults.shared.getString(forKey: SharedKeys.dns)
    }

    func getPublicKey() -> String? {
        let publicKey = PrivateKey.init(base64Key: getPrivateKey()!)?.publicKey.base64Key
        return publicKey
    }

    //Generate private key if not available and save it to keychain.
    func getPrivateKey() -> String? {
        guard let currentKey = JNKeychain.loadValue(forKey: SharedKeys.privateKey, forAccessGroup: SharedKeys.sharedKeychainGroup) as? String else {
            let privateKey = PrivateKey.init().base64Key
            JNKeychain.saveValue(privateKey, forKey: SharedKeys.privateKey, forAccessGroup: SharedKeys.sharedKeychainGroup)
            return privateKey
        }
        return currentKey
    }

    // wg Init
    func initialized() -> Bool {
        return getWgInitResponse() != nil
    }

    func getWgInitResponse()-> DynamicWireGuardConfig?{
        presharedKey = SharedSecretDefaults.shared.getString(forKey: SharedKeys.preSharedKey)
        allowedIps = SharedSecretDefaults.shared.getString(forKey: SharedKeys.allowedIp)
        if presharedKey != nil && allowedIps != nil {
            let config = DynamicWireGuardConfig()
            config.presharedKey = presharedKey
            config.allowedIPs = allowedIps
            return config
        }
        return nil
    }

    func saveInitResponse(config: DynamicWireGuardConfig){
        self.presharedKey = config.presharedKey
        self.allowedIps = config.allowedIPs
        SharedSecretDefaults.shared.setString(config.presharedKey, forKey: SharedKeys.preSharedKey)
        SharedSecretDefaults.shared.setString(config.allowedIPs, forKey: SharedKeys.allowedIp)
    }


    // wg Connect
    func saveConnectResponse(config: DynamicWireGuardConnect){
        self.dns = config.dns
        self.address = config.address
        SharedSecretDefaults.shared.setString(config.address, forKey: SharedKeys.address)
        SharedSecretDefaults.shared.setString(config.dns, forKey: SharedKeys.dns)
    }

    func setNodeToConnect(serverEndPoint: String, serverHostName: String, serverPublicKey: String, port: String){
        self.serverEndPoint = serverEndPoint
        self.serverHostName = serverHostName
        self.serverPublicKey = serverPublicKey
        self.port = port
        SharedSecretDefaults.shared.setString(serverEndPoint, forKey:SharedKeys.serverEndPoint)
        SharedSecretDefaults.shared.setString(serverHostName, forKey: SharedKeys.serverHostName)
        SharedSecretDefaults.shared.setString(serverPublicKey, forKey: SharedKeys.serverPublicKey)
        SharedSecretDefaults.shared.setString(port, forKey: SharedKeys.wgPort)
    }

    //Delete credentials and key if user status changes
    func delete(){
        JNKeychain.deleteValue(forKey: SharedKeys.privateKey, forAccessGroup: SharedKeys.sharedKeychainGroup)
        self.dns = nil
        self.address = nil
        self.presharedKey = nil
        self.allowedIps = nil
        SharedSecretDefaults.shared.removeObjects(forKey: [ SharedKeys.preSharedKey, SharedKeys.allowedIp, SharedKeys.dns,SharedKeys.address])
    }

    func asWgCredentialsString() -> String?{
        let udpStuffing = preferences.isCircumventCensorshipEnabled()
        if let privateKey = getPrivateKey(),
           let address = address,
           let dns = dns,
           let allowedIps = allowedIps,
           let presharedKey = presharedKey,
           let serverPublicKey = serverPublicKey,
           let serverEndPoint = serverEndPoint,
           let port = port {
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
        return "Endpoint: \(serverEndPoint ?? "") Hostname: \(serverHostName ?? "") Server public key: \(serverPublicKey ?? "") \n User public key: \(getPublicKey()  ?? "") Allowed Ip: \(allowedIps ?? "") Preshared key: \(presharedKey ?? "") Address: \(address ?? "") Port: \(port ?? "") Dns: \(dns ?? "")"
    }
}

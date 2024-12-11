//
//  VPNUserSettings.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//
import NetworkExtension
import UIKit
import WireGuardKit

struct VPNUserSettings: CustomStringConvertible {
    let killSwitch: Bool
    let allowLan: Bool
    let isRFC: Bool
    let isCircumventCensorshipEnabled: Bool
    let onDemandRules: [NEOnDemandRule]?
    var deleteOldestKey = false
    var description: String {
        return "User Settings: [KillSwitch: \(killSwitch) allowLan: \(allowLan), isRfc: \(isRFC), CircumventCensorship: \(isCircumventCensorshipEnabled)]"
    }
}

struct IKEv2VPNConfiguration: VPNConfiguration {
    let username: String
    let auth: Data
    let hostname: String
    let ip: String
    var description: String {
        return "IKEv2: [username: \(username) ip: \(ip) hostname: \(hostname)] auth: \(auth)"
    }

    func buildProtocol(settings: VPNUserSettings, manager: NEVPNManager) {
        let ikeV2Protocol = NEVPNProtocolIKEv2()
        ikeV2Protocol.disconnectOnSleep = false
        ikeV2Protocol.authenticationMethod = .none
        ikeV2Protocol.useExtendedAuthentication = true
        ikeV2Protocol.enablePFS = true
        // Using direct ip for server does not work in iOS <=13
        let legacyOS = NSString(string: UIDevice.current.systemVersion).doubleValue <= 13
        // Changes for the ikev2 issue on ios 16 and kill switch on
        if #available(iOS 16.0, *) {
            if settings.killSwitch || !settings.allowLan {
                ikeV2Protocol.remoteIdentifier = hostname
                ikeV2Protocol.localIdentifier = username
                ikeV2Protocol.serverAddress = hostname
            } else {
                ikeV2Protocol.serverAddress = ip
                ikeV2Protocol.serverCertificateCommonName = hostname
            }
        } else if legacyOS {
            ikeV2Protocol.remoteIdentifier = hostname
            ikeV2Protocol.localIdentifier = username
            ikeV2Protocol.serverAddress = hostname
        } else {
            ikeV2Protocol.serverAddress = ip
            ikeV2Protocol.serverCertificateCommonName = hostname
        }

        ikeV2Protocol.passwordReference = auth
        ikeV2Protocol.username = username
        ikeV2Protocol.sharedSecretReference = auth
        #if os(iOS)
            if #available(iOS 13.0, *) {
                // changing enableFallback to true for https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/362
                ikeV2Protocol.enableFallback = true
            }
        #endif
        ikeV2Protocol.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
        ikeV2Protocol.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
        ikeV2Protocol.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
        ikeV2Protocol.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
        ikeV2Protocol.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
        ikeV2Protocol.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
        ikeV2Protocol.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
        ikeV2Protocol.childSecurityAssociationParameters.lifetimeMinutes = 1440
        manager.protocolConfiguration = ikeV2Protocol
    }
}

struct OpenVPNConfiguration: VPNConfiguration {
    let proto: String
    let ip: String
    let username: String?
    let password: String?
    let path: String
    let data: Data
    var description: String {
        return "OpenVPN: [proto: \(proto) ip: \(ip)  username: \(username ?? "N/A") password: \(password ?? "N/A") path: \(path) data: \(data)]"
    }

    func buildProtocol(settings _: VPNUserSettings, manager: NEVPNManager) throws {
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.username = TextsAsset.openVPN
        tunnelProtocol.serverAddress = ip
        tunnelProtocol.providerBundleIdentifier = "\(Bundle.main.bundleID ?? "").PacketTunnel"
        if let configUsername = username, let configPassword = password {
            tunnelProtocol.providerConfiguration = ["ovpn": data,
                                                    "username": configUsername,
                                                    "password": configPassword,
                                                    "compressionEnabled": false]
        } else {
            tunnelProtocol.providerConfiguration = ["ovpn": data,
                                                    "compressionEnabled": false]
        }

        tunnelProtocol.disconnectOnSleep = false
        manager.protocolConfiguration = tunnelProtocol
    }
}

struct WireguardVPNConfiguration: VPNConfiguration {
    let content: TunnelConfiguration
    var description: String {
        return "Wireguard: [content: \(content.asWgQuickConfig())"
    }

    func buildProtocol(settings _: VPNUserSettings, manager: NEVPNManager) throws {
        guard let manager = manager as? NETunnelProviderManager else {
            throw VPNConfigurationErrors.incorrectVPNManager
        }
        manager.setTunnelConfiguration(content, username: TextsAsset.wireGuard, description: Constants.appName)
    }
}

protocol VPNConfiguration: CustomStringConvertible {
    func buildProtocol(settings: VPNUserSettings, manager: NEVPNManager) throws
}

extension VPNConfiguration {
    func applySettings(settings: VPNUserSettings, manager: NEVPNManager) {
        #if os(iOS)
            // For Non RFC address. set [includeallnetworks​ =  True & excludeLocalNetworks​ = False]
            // For RFC address follow user settings.
            if #available(iOS 15.1, *) {
                manager.protocolConfiguration?.includeAllNetworks = settings.isRFC ? settings.killSwitch : true
                manager.protocolConfiguration?.excludeLocalNetworks = settings.isRFC ? settings.allowLan : false
            }
            // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
            if #available(iOS 16.0, *) {
                manager.protocolConfiguration?.includeAllNetworks = settings.allowLan
            }
        #endif
        manager.onDemandRules?.removeAll()
        manager.onDemandRules = settings.onDemandRules
        manager.isEnabled = true
        manager.isOnDemandEnabled = true
        manager.localizedDescription = Constants.appName
    }
}

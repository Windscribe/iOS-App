//
//  ConfigurationsManager+IKEV2.swift
//  Windscribe
//
//  Created by Andre Fonseca on 23/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import UIKit

extension ConfigurationsManager {
    func configureIKEV2WithSavedCredentials(with selectedNode: SelectedNode?,
                                            userSettings: VPNUserSettings) async throws -> Bool {
        guard let selectedNode = selectedNode else {
            logger.logE(self, "Failed to configure IKEv2 profile. \(Errors.hostnameNotFound.localizedDescription)")
            throw Errors.hostnameNotFound
        }
        let manager = iKEV2Manager() ?? NEVPNManager.shared()
        let ip = selectedNode.ip1 ?? selectedNode.staticIpToConnect
        guard let ip = ip else {
            logger.logE(self, "Ip1 and ip3 are not avaialble to configure this profile.")
            throw Errors.ipNotAvailable
        }
        logger.logD(self, "Configuring VPN profile with saved credentials. \(selectedNode.hostname)")

        var base64username = ""
        var base64password = ""
        if let staticIPCredentials = selectedNode.staticIPCredentials,
           let username = staticIPCredentials.username,
           let password = staticIPCredentials.password {
            base64username = username
            base64password = password
        } else if let credentials = localDatabase.getIKEv2ServerCredentials() {
            base64username = credentials.username.base64Decoded()
            base64password = credentials.password.base64Decoded()
        }
        if base64username == "" || base64password == "" {
            logger.logE(self, "Can't establish a VPN connection, missing authentication values.")
            throw Errors.missingAuthenticationValues
        }
        keychainDb.save(username: base64username, password: base64password)
        return try await configureIKEV2(manager: manager,
                                        username: base64username,
                                        dnsHostname: selectedNode.dnsHostname,
                                        hostname: selectedNode.hostname,
                                        ip: ip,
                                        userSettings: userSettings)
    }

    func configureIKEV2(manager: NEVPNManager, username: String,
                        dnsHostname _: String, hostname: String,
                        ip: String, userSettings: VPNUserSettings) async throws -> Bool {
        try await manager.loadFromPreferences()
        let serverCredentials = keychainDb.retrieve(username: username)
        let ikeV2Protocol = NEVPNProtocolIKEv2()
        ikeV2Protocol.disconnectOnSleep = false
        ikeV2Protocol.authenticationMethod = .none
        ikeV2Protocol.useExtendedAuthentication = true
        ikeV2Protocol.enablePFS = true
        // Using direct ip for server does not work in iOS <=13
        let legacyOS = await NSString(string: UIDevice.current.systemVersion).doubleValue <= 13
        // Changes for the ikev2 issue on ios 16 and kill switch on
        if #available(iOS 16.0, *) {
            if userSettings.killSwitch || !userSettings.allowLan {
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

        ikeV2Protocol.passwordReference = serverCredentials
        ikeV2Protocol.username = username
        ikeV2Protocol.sharedSecretReference = serverCredentials
        ikeV2Protocol.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
        ikeV2Protocol.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
        ikeV2Protocol.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
        ikeV2Protocol.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
        ikeV2Protocol.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
        ikeV2Protocol.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
        ikeV2Protocol.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
        ikeV2Protocol.childSecurityAssociationParameters.lifetimeMinutes = 1440

        #if os(iOS)
            // changing enableFallback to true for https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/362
            ikeV2Protocol.enableFallback = true
            manager.protocolConfiguration = ikeV2Protocol
            // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
            if #available(iOS 15.1, *) {
                manager.protocolConfiguration?.includeAllNetworks = userSettings.isRFC ? userSettings.killSwitch : true
                manager.protocolConfiguration?.excludeLocalNetworks = userSettings.isRFC ? userSettings.allowLan : false
            }
            // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
            if #available(iOS 16.0, *) {
                manager.protocolConfiguration?.includeAllNetworks = userSettings.allowLan
            }
        #else
            manager.protocolConfiguration = ikeV2Protocol
        #endif
        manager.onDemandRules?.removeAll()
        manager.onDemandRules = userSettings.onDemandRules
        manager.isEnabled = true
        manager.localizedDescription = Constants.appName
        do {
            try await saveThrowing(manager: manager)
        } catch {
            guard let error = error as? Errors else { throw Errors.notDefined }
            logger.logE(self, "Error when saving vpn preferences \(error.description).")
            throw error
        }
        logger.logD(self, "VPN configuration successful. Username: \(username)")
        logger.logD(self, "KillSwitch option set by user is \(userSettings.killSwitch)")
        logger.logD(self, "Allow lan option set by user is \(userSettings.allowLan)")
        #if os(iOS)
            if #available(iOS 15.1, *) {
                logger.logD(self, "KillSwitch in IKEv2 VPNManager is \(String(describing: manager.protocolConfiguration?.includeAllNetworks))")
                logger.logD(self, "Allow lan in IKEv2 VPNManager is \(String(describing: manager.protocolConfiguration?.excludeLocalNetworks))")
            }
        #endif
        return true
    }
}

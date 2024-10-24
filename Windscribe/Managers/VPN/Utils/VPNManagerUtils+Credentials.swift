//
//  VPNManagerUtils+Credentials.swift
//  Windscribe
//
//  Created by Andre Fonseca on 23/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension

extension VPNManagerUtils {
    func configureIKEV2WithSavedCredentials(with selectedNode: SelectedNode?) async throws -> Bool {
        guard let selectedNode = selectedNode else {
            logger.logE(self, "Failed to configure IKEv2 profile. \(Errors.hostnameNotFound.localizedDescription)")
            throw Errors.hostnameNotFound
        }
        
        let ip = selectedNode.ip1 ?? selectedNode.staticIpToConnect
        guard let ip = ip else {
            logger.logE(self, "Ip1 and ip3 are not avaialble to configure this profile.")
            throw Errors.ipNotAvailable
        }
        logger.logD(self, "Configuring VPN profile with saved credentials. \(selectedNode.hostname)")
        
        var base64username = ""
        var base64password = ""
        if let staticIPCredentials = VPNManager.shared.selectedNode?.staticIPCredentials,
           let username = staticIPCredentials.username,
           let password = staticIPCredentials.password {
            base64username = username
            base64password = password
        } else {
            if let credentials = localDatabase.getIKEv2ServerCredentials() {
                base64username = credentials.username.base64Decoded()
                base64password = credentials.password.base64Decoded()
            }
        }
        if base64username == "" ||
            base64password == "" {
            logger.logE(self, "Can't establish a VPN connection, missing authentication values.")
            throw Errors.missingAuthenticationValues
        } else {
            keychainDb.save(username: base64username,
                            password: base64password)
//            configure(username: base64username,
//                      dnsHostname: selectedNode.dnsHostname,
//                      hostname: selectedNode.hostname, ip: ip) { (result, error) in
//                completion(result, error)
//            }
            return false
        }
    }
    
    func configureIKEV2(manager: NEVPNManager,
                        username: String,
                   dnsHostname: String,
                   hostname: String,
                   ip: String,
                   completion: @escaping (_ result: Bool,
                                          _ error: String?) -> Void ) {
//        loadData()
        manager.loadFromPreferences { (error) in
            guard error != nil else { return }
            if error == nil {
                let serverCredentials = self.keychainDb.retrieve(username: username)
                let ikeV2Protocol = NEVPNProtocolIKEv2()
                ikeV2Protocol.disconnectOnSleep = false
                ikeV2Protocol.authenticationMethod = .none
                ikeV2Protocol.useExtendedAuthentication = true
                ikeV2Protocol.enablePFS = true
                // Using direct ip for server does not work in iOS <=13
                let legacyOS = NSString(string: UIDevice.current.systemVersion).doubleValue <= 13
                // Changes for the ikev2 issue on ios 16 and kill switch on
                if #available(iOS 16.0, *) {
                    if self.killSwitch || !self.allowLane {
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
                #if os(iOS)
                if #available(iOS 13.0, *) {
                    // changing enableFallback to true for https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/362
                    ikeV2Protocol.enableFallback = true
                }
                #endif
                ikeV2Protocol.ikeSecurityAssociationParameters.encryptionAlgorithm =  NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
                ikeV2Protocol.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
                ikeV2Protocol.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
                ikeV2Protocol.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
                ikeV2Protocol.childSecurityAssociationParameters.encryptionAlgorithm =  NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
                ikeV2Protocol.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
                ikeV2Protocol.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
                ikeV2Protocol.childSecurityAssociationParameters.lifetimeMinutes = 1440

                self.neVPNManager.protocolConfiguration = ikeV2Protocol

#if os(iOS)

                // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
                if #available(iOS 15.1, *) {
                    self.neVPNManager.protocolConfiguration?.includeAllNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.killSwitch  : true
                    self.neVPNManager.protocolConfiguration?.excludeLocalNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.allowLane  : false
                }
                // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
                if #available(iOS 16.0, *) {
                    if !self.allowLane {
                        self.neVPNManager.protocolConfiguration?.includeAllNetworks = true
                    }
                }
#endif

                self.neVPNManager.onDemandRules?.removeAll()
                self.neVPNManager.onDemandRules = VPNManager.shared.getOnDemandRules()
                self.neVPNManager.isEnabled = true
                self.neVPNManager.localizedDescription = Constants.appName
                self.neVPNManager.saveToPreferences(completionHandler: { (error) in
                    self.neVPNManager.loadFromPreferences { (error) in
                        if error == nil {
                            self.logger.logD(self, "VPN configuration successful. Username: \(username)")
                            completion(true, nil)
                        } else {
                            self.logger.logE(self, "Error when saving vpn preferences\(error.debugDescription).")
                            completion(false, error?.localizedDescription)
                        }
                    }
                })
                self.logger.logD(self, "KillSwitch option set by user is \(self.killSwitch )")
                self.logger.logD(self, "Allow lan option set by user is \(self.allowLane )")

#if os(iOS)

                if #available(iOS 15.1, *) {
                    self.logger.logD(self, "KillSwitch in IKEv2 VPNManager is \( String(describing: self.neVPNManager.protocolConfiguration?.includeAllNetworks))")
                    self.logger.logD(self, "Allow lan in IKEv2 VPNManager is \( String(describing: self.neVPNManager.protocolConfiguration?.excludeLocalNetworks))")
                }
#endif
            }
        }
    }
}
    

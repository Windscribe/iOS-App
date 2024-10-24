//
//  Untitled.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import UIKit

extension VPNManagerUtils {
    func configureOpenVPNWithSavedCredentials(with selectedNode: SelectedNode?,
                                              for manager: NEVPNManager) async throws -> Bool {
        guard let selectedNode = selectedNode,
              let x509Name = selectedNode.ovpnX509 else {
            throw Errors.hostnameNotFound
        }
        
        var serverAddress = selectedNode.serverAddress
        logger.logD( OpenVPNManager.self, "Configuring VPN profile with saved credentials. \(String(describing: serverAddress))")
        
        var base64username = ""
        var base64password = ""
        var protocolType = ConnectionManager.shared.getNextProtocol().protocolName
        var port = ConnectionManager.shared.getNextProtocol().portName
        logger.logD(self, "\(protocolType) \(port)")
        
        guard VPNManager.shared.selectedNode?.customConfig?.authRequired ?? false else {
            return try await configureOpenVPN(manager: manager,
                                              username: base64username,
                                              password: base64password,
                                              protocolType: protocolType,
                                              serverAddress: serverAddress,
                                              port: port,
                                              x509Name: x509Name,
                                              proxyInfo: nil)
        }
        
        if let staticIPCredentials = selectedNode.staticIPCredentials,
           let username = staticIPCredentials.username,
           let password = staticIPCredentials.password {
            base64username = username
            base64password = password
        } else if let credentials = localDatabase.getOpenVPNServerCredentials() {
            base64username = credentials.username.base64Decoded()
            base64password = credentials.password.base64Decoded()
        }
        
        guard base64username != "" && base64password != "" else {
            logger.logE( OpenVPNManager.self, "Can't establish a VPN connection, missing authentication values.")
            throw Errors.missingAuthenticationValues
        }
        
        // Build proxy info
        var proxyInfo: ProxyInfo?
        if protocolType == stealth  || protocolType == wsTunnel {
            var proxyProtocol = ProxyType.wstunnel
            var remoteAddress = selectedNode.ip1
            if protocolType == stealth {
                proxyProtocol = .stunnel
                remoteAddress = selectedNode.ip3
            }
            guard let remoteAddress = remoteAddress else { throw Errors.missingRemoteAddress }
            
            proxyInfo = ProxyInfo(remoteServer: remoteAddress, remotePort: port, proxyType: proxyProtocol)
            if proxyInfo != nil {
                // Connect OpenVPN to proxy
                serverAddress = Proxy.localAddress
                port = Proxy.defaultProxyPort
                protocolType = Proxy.internalProtocol
            }
        }
        
        keychainDb.save(username: base64username, password: base64password)
        return try await configureOpenVPN(manager: manager,
                                          username: base64username,
                                          password: base64password,
                                          protocolType: protocolType,
                                          serverAddress: serverAddress,
                                          port: port,
                                          compressionEnabled: true,
                                          x509Name: x509Name,
                                          proxyInfo: proxyInfo)
    }
    
    func configureOpenVPN(manager: NEVPNManager,
                          username: String,
                          password: String,
                          protocolType: String,
                          serverAddress: String,
                          port: String,
                          compressionEnabled: Bool? = false,
                          x509Name: String?,
                          proxyInfo: ProxyInfo? = nil) async throws -> Bool {
        providerManager?.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.getConfiguration(username: username,
                                      password: password,
                                      protocolType: protocolType,
                                      serverAddress: serverAddress,
                                      port: port,
                                      x509Name: x509Name,
                                      proxyInfo: proxyInfo,
                                      completion: { (result, configUsername, configPassword, _, configData) in
                    if result {
                        guard let configData = configData else { return }
                        let tunnelProtocol = NETunnelProviderProtocol()
                        tunnelProtocol.username = TextsAsset.openVPN
                        tunnelProtocol.serverAddress = serverAddress
                        tunnelProtocol.providerBundleIdentifier = "\(Bundle.main.bundleID ?? "").PacketTunnel"
                        if let configUsername = configUsername, let configPassword = configPassword {
                            tunnelProtocol.providerConfiguration = ["ovpn": configData,
                                                                    "username": configUsername,
                                                                    "password": configPassword,
                                                                    "compressionEnabled": compressionEnabled ?? false]
                        } else {
                            tunnelProtocol.providerConfiguration = ["ovpn": configData,
                                                                    "compressionEnabled": compressionEnabled ?? false]
                        }
                        
                        tunnelProtocol.disconnectOnSleep = false
                        
                        self.providerManager.protocolConfiguration = tunnelProtocol
                        
#if os(iOS)
                        
                        // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
                        if #available(iOS 15.1, *) {
                            
                            self.providerManager.protocolConfiguration?.includeAllNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.killSwitch : true
                            self.providerManager.protocolConfiguration?.excludeLocalNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.allowLane : false
                        }
                        // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
                        if #available(iOS 16.0, *) {
                            if !self.allowLane {
                                self.providerManager.protocolConfiguration?.includeAllNetworks = true
                            }
                        }
#endif
                        self.providerManager.onDemandRules?.removeAll()
                        self.providerManager.onDemandRules = VPNManager.shared.getOnDemandRules()
                        self.providerManager.isEnabled = true
                        self.providerManager.localizedDescription = Constants.appName
                        self.providerManager.saveToPreferences(completionHandler: { (error) in
                            if error == nil {
                                self.providerManager.loadFromPreferences(completionHandler: { _ in
                                    self.logger.logD( OpenVPNManager.self, "VPN configuration successful. Username: \(username)")
                                    completion(true, nil)
                                })
                            } else {
                                completion(false, "Error when loading vpn prefences.")
                                self.logger.logE( OpenVPNManager.self, "Error when loading vpn prefences. \(String(describing: error?.localizedDescription))")
                                
                            }
                        })
                    }
                })
            } else {
                completion(false, "Error when loading vpn prefences.")
                self.logger.logE( OpenVPNManager.self, "Error when loading vpn prefences. \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
}

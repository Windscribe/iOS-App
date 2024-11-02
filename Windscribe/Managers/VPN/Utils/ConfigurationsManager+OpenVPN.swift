//
//  ConfigurationsManager+OpenVPN.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import UIKit

extension ConfigurationsManager {
    func configureOpenVPNWithSavedCredentials(with selectedNode: SelectedNode?,
                                              userSettings: VPNUserSettings) async throws -> Bool {
        guard let selectedNode = selectedNode,
              let x509Name = selectedNode.ovpnX509
        else {
            throw Errors.hostnameNotFound
        }

        var serverAddress = selectedNode.serverAddress
        logger.logD(ConfigurationsManager.self, "Configuring VPN profile with saved credentials. \(String(describing: serverAddress))")
        let manager = openVPNdManager() as? NETunnelProviderManager ?? NETunnelProviderManager()
        var base64username = ""
        var base64password = ""
        var protocolType = ConnectionManager.shared.getNextProtocol().protocolName
        var port = ConnectionManager.shared.getNextProtocol().portName
        logger.logD(self, "\(protocolType) \(port)")

        guard VPNManager.shared.selectedNode?.customConfig?.authRequired ?? false else {
            return try await configureOpenVPN(manager: manager,
                                              selectedNode: selectedNode,
                                              userSettings: userSettings,
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
            logger.logE(ConfigurationsManager.self, "Can't establish a VPN connection, missing authentication values.")
            throw Errors.missingAuthenticationValues
        }

        // Build proxy info
        var proxyInfo: ProxyInfo?
        if protocolType == stealth || protocolType == wsTunnel {
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
                                          selectedNode: selectedNode,
                                          userSettings: userSettings,
                                          username: base64username,
                                          password: base64password,
                                          protocolType: protocolType,
                                          serverAddress: serverAddress,
                                          port: port,
                                          compressionEnabled: true,
                                          x509Name: x509Name,
                                          proxyInfo: proxyInfo)
    }

    func configureOpenVPNWithCustomConfig(with selectedNode: SelectedNode?,
                                          userSettings: VPNUserSettings) async throws -> Bool {
        guard let selectedNode = selectedNode else {
            throw Errors.hostnameNotFound
        }

        let providerManager = openVPNdManager() as? NETunnelProviderManager ?? NETunnelProviderManager()
        logger.logD(ConfigurationsManager.self, "Configuring VPN profile with custom configuration. \(String(describing: selectedNode.serverAddress))")
        guard providerManager.connection.status != .connecting,
              let customConfig = selectedNode.customConfig,
              let protocolType = customConfig.protocolType,
              let port = customConfig.port else { return false }

        var username = ""
        var password = ""
        if customConfig.authRequired ?? false {
            if let usern = customConfig.username, let pass = customConfig.password {
                username = usern
                password = pass
            } else { return false }
        }
        return try await configureOpenVPN(manager: providerManager,
                                          selectedNode: selectedNode,
                                          userSettings: userSettings,
                                          username: username,
                                          password: password,
                                          protocolType: protocolType,
                                          serverAddress: selectedNode.serverAddress,
                                          port: port,
                                          x509Name: nil)
    }

    func configureOpenVPN(manager: NEVPNManager,
                          selectedNode: SelectedNode?,
                          userSettings: VPNUserSettings,
                          username: String,
                          password: String,
                          protocolType: String,
                          serverAddress: String,
                          port: String,
                          compressionEnabled: Bool? = false,
                          x509Name: String?,
                          proxyInfo: ProxyInfo? = nil) async throws -> Bool {
        guard let configuration = await getConfiguration(selectedNode: selectedNode,
                                                         userSettings: userSettings,
                                                         username: username,
                                                         password: password,
                                                         protocolType: protocolType,
                                                         serverAddress: serverAddress,
                                                         port: port,
                                                         x509Name: x509Name,
                                                         proxyInfo: proxyInfo)
        else {
            return false
        }

        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.username = TextsAsset.openVPN
        tunnelProtocol.serverAddress = serverAddress
        tunnelProtocol.providerBundleIdentifier = "\(Bundle.main.bundleID ?? "").PacketTunnel"
        if let configUsername = configuration.username, let configPassword = configuration.password {
            tunnelProtocol.providerConfiguration = ["ovpn": configuration.data,
                                                    "username": configUsername,
                                                    "password": configPassword,
                                                    "compressionEnabled": compressionEnabled ?? false]
        } else {
            tunnelProtocol.providerConfiguration = ["ovpn": configuration.data,
                                                    "compressionEnabled": compressionEnabled ?? false]
        }

        tunnelProtocol.disconnectOnSleep = false
        manager.protocolConfiguration = tunnelProtocol

        #if os(iOS)
            if #available(iOS 15.1, *) {
                manager.protocolConfiguration?.includeAllNetworks = userSettings.isRFC ? userSettings.killSwitch : true
                manager.protocolConfiguration?.excludeLocalNetworks = userSettings.isRFC ? userSettings.allowLane : false
            }
            // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
            if #available(iOS 16.0, *) {
                manager.protocolConfiguration?.includeAllNetworks = manager.protocolConfiguration?.includeAllNetworks ?? !userSettings.allowLane
            }
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
        logger.logD(ConfigurationsManager.self, "VPN configuration successful. Username: \(username)")

        return true
    }

    func getConfiguration(selectedNode: SelectedNode?,
                          userSettings: VPNUserSettings,
                          username: String,
                          password: String,
                          protocolType: String,
                          serverAddress: String,
                          port: String,
                          x509Name: String?,
                          proxyInfo: ProxyInfo?) async -> OpenVPNConfiguration? {
        let openVPNConfigFilePath = FilePaths.openVPN
        if let customConfig = selectedNode?.customConfig,
           let customConfigId = customConfig.id,
           let authRequired = customConfig.authRequired {
            let configFilePath = "\(customConfigId).ovpn"
            guard let configData = fileDatabase.readFile(path: configFilePath) else { return nil }
            if customConfig.username != "",
               customConfig.password != "" {
                let user = customConfig.username!.base64Decoded() == "" ? customConfig.username! : customConfig.username!.base64Decoded()
                let pass = customConfig.password!.base64Decoded() == "" ? customConfig.password! : customConfig.password!.base64Decoded()
                return OpenVPNConfiguration(proto: protocolType, ip: customConfig.serverAddress ?? "", username: user, password: pass, path: configFilePath, data: configData)

            } else {
                return OpenVPNConfiguration(proto: protocolType, ip: customConfig.serverAddress ?? "", username: nil, password: nil, path: configFilePath, data: configData)
            }
        } else {
            let protoLine = "proto \(protocolType.lowercased())"
            let remoteLine = "remote \(serverAddress) \(port)"
            let x509NameLine = "verify-x509-name \(x509Name!) name"
            let proxyLine = proxyInfo?.text
            logger.logD(ConfigurationsManager.self, proxyLine?.debugDescription ?? "")
            guard let configData = fileDatabase.readFile(path: openVPNConfigFilePath),
                  let stringData = String(data: configData, encoding: String.Encoding.utf8)
            else { return nil }
            var lines = stringData.components(separatedBy: "\n")
            lines.removeAll { s in
                s.starts(with: "local-proxy")
            }
            var configFound = false
            var x509Found = false
            for (index, line) in lines.enumerated() {
                if line.contains("proto ") {
                    lines[index] = protoLine
                    configFound = true
                }
                if line.contains("remote ") {
                    lines[index] = remoteLine
                    configFound = true
                }
                if line.starts(with: "verify-x509-name") {
                    lines[index] = x509NameLine
                    x509Found = true
                }
            }
            if configFound == false {
                lines.insert(protoLine, at: 2)
                lines.insert(remoteLine, at: 3)
            }

            if x509Found == false {
                lines.insert(x509NameLine, at: 4)
            }

            if let proxyLine = proxyLine {
                lines.append(proxyLine)
            }
            if userSettings.isCircumventCensorshipEnabled {
                lines.append("udp-stuffing")
                lines.append("tcp-split-reset")
            }
            guard let appendedConfigData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else { return nil }

            fileDatabase.removeFile(path: FilePaths.openVPN)
            fileDatabase.saveFile(data: appendedConfigData,
                                  path: FilePaths.openVPN)
            return OpenVPNConfiguration(proto: protocolType, ip: serverAddress, username: username, password: password, path: openVPNConfigFilePath, data: appendedConfigData)
        }
    }
}

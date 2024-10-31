//
//  ConfigurationsManager+config.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-30.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import WireGuardKit

extension ConfigurationsManager {
    func connectAsync () async {
        let locationID = "89"
        let proto = TextsAsset.iKEv2
        let port = "500"
        let userSettings = VPNUserSettings(killSwitch: false, allowLane: true, isRFC: true, isCircumventCensorshipEnabled: true, onDemandRules: [])
        do {
            logger.logD(self, "Building VPN Conifguration for [\(locationID) \(proto) \(port)]")
            let config = try await buildConfig(location: locationID, proto: proto, port: port, userSettings: userSettings)
            logger.logD(self, config.description)
        } catch let error {
            logger.logD(self, "Unable to build VPN configuration error: \(error)")
        }
    }

    func buildConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) async throws -> VPNConfiguration {
        if [udp, tcp, stealth, wsTunnel].contains(proto) {
            return try buildOpenVPNConfig(location: location, proto: proto, port: port, userSettings: userSettings)
        } else if proto == TextsAsset.iKEv2 {
            return try buildIKEv2Config(location: location)
        } else {
            return try await buildWgConfig(location: location, port: port)
        }
    }

    private func wgConfigurationFromPath(path: String) throws -> WireguardVPNConfiguration {
        guard let configData = fileDatabase.readFile(path: path) else {
            throw VPNConfigurationErrors.configNotFound
        }
        guard let stringData = String(data: configData, encoding: String.Encoding.utf8) else {
            throw VPNConfigurationErrors.configNotFound
        }
        let tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: stringData, called: path)
        return WireguardVPNConfiguration(content: tunnelConfiguration)
    }

    private func buildWgConfig(location: String, port: String) async throws -> WireguardVPNConfiguration {
        switch try getLocationType(id: location) {
            case .server:
                let location = try getLocation(id: location)
                let node = try getRandomNode(group: location.1)
                let ip = node.ip3
                let hostname = node.hostname
                let publickey = location.1.wgPublicKey
                try await saveWgConfig(ip: ip, hostname: hostname, serverPublicKey: publickey, port: port)
                return try wgConfigurationFromPath(path: FilePaths.wireGuard)
            case .staticIP:
                let location = try getStaticIPLocation(id: location)
                guard let node = location.nodes.toArray().randomElement() else {
                    throw VPNConfigurationErrors.noValidNodeFound
                }
                let ip = node.ip
                let hostname = node.hostname
                let publickey = location.wgPublicKey
                try await saveWgConfig(ip: ip, hostname: hostname, serverPublicKey: publickey, port: port)
                return try wgConfigurationFromPath(path: FilePaths.wireGuard)

            default:
                let locationID = getId(location: location)
                let configFilePath = "\(locationID).conf"
                guard let configData = fileDatabase.readFile(path: configFilePath) else {
                    throw VPNConfigurationErrors.configNotFound
                }
                return try wgConfigurationFromPath(path: configFilePath)
        }
    }

    private func saveWgConfig(ip: String, hostname: String, serverPublicKey: String, port: String) async throws {
        wgCredentials.setNodeToConnect(serverEndPoint: ip, serverHostName: hostname, serverPublicKey: serverPublicKey, port: port)
        return try await wgRepository.getCredentials().value
    }

    private func buildIKEv2Config(location: String) throws -> IKEv2VPNConfiguration {
        switch try getLocationType(id: location) {
        case .server:
                guard let credentials = localDatabase.getIKEv2ServerCredentials() else {
                    throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.iKEv2)
                }
            let username = credentials.username
            let password = credentials.password
            keychainDb.save(username: username, password: password)
            let location = try getLocation(id: location)
            let node = try getRandomNode(group: location.1)
            let ip = node.ip
            let hostname = node.hostname
            return IKEv2VPNConfiguration(username: username, hostname: hostname, ip: ip)
        case .staticIP:
            let location = try getStaticIPLocation(id: location)
            guard let node = location.nodes.toArray().randomElement() else {
                throw VPNConfigurationErrors.noValidNodeFound
            }
            let ip = node.ip
            let hostname = node.hostname
            guard let credentials = location.credentials.first else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.iKEv2)
            }
            let username = credentials.username
            let password = credentials.password
                keychainDb.save(username: username, password: password)
            return IKEv2VPNConfiguration(username: username, hostname: hostname, ip: ip)
            default:
                throw VPNConfigurationErrors.customConfigSupportNotAvailable
        }
    }

    private func buildOpenVPNConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) throws -> OpenVPNConfiguration {
        let locationID = getId(location: location)
        switch try getLocationType(id: location) {
            case .server:
                guard let credentials = localDatabase.getOpenVPNServerCredentials() else { throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN)}
                let username = credentials.username
                let password = credentials.password
                let location = try getLocation(id: location)
                let node = try getRandomNode(group: location.1)
                let proxyInfo = getProxyInfo(proto: proto, port: port, ip1: node.ip, ip3: node.ip3)
                let hostname = node.hostname
                let config = try editOpenVPNConfig(proto: proto, serverAddress: hostname, port: port, x509Name: location.1.ovpnX509, proxyInfo: proxyInfo, userSettings: userSettings)

                return OpenVPNConfiguration(proto: proto, username: username, password: password, path: config.0, data: config.1)
            case .staticIP:
                let location = try getStaticIPLocation(id: location)
                guard let node = location.nodes.toArray().randomElement() else {
                    throw VPNConfigurationErrors.noValidNodeFound
                }
                guard let credentials = location.credentials.first else {
                    throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN)
                }
                let username = credentials.username
                let password = credentials.password
                let hostname = node.hostname
                let config = try editOpenVPNConfig(proto: proto, serverAddress: hostname, port: port, x509Name: location.ovpnX509, proxyInfo: nil, userSettings: userSettings)

                return OpenVPNConfiguration(proto: proto, username: username, password: password, path: config.0, data: config.1)
            default:
                let configFilePath = "\(getId(location: locationID)).ovpn"
                guard let configData = fileDatabase.readFile(path: configFilePath) else {
                    throw VPNConfigurationErrors.configNotFound
                }
                guard let config = localDatabase.getCustomConfigs().first(where: {$0.id == locationID})?.getModel() else {
                    throw VPNConfigurationErrors.configNotFound
                }
                return OpenVPNConfiguration(proto: config.protocolType ?? udp, username: config.username, password: config.password, path: configFilePath, data: configData)
        }
    }

    private func getProxyInfo(proto: String, port: String, ip1: String, ip3: String) -> ProxyInfo? {
        if ![stealth, wsTunnel].contains(proto) {
           return nil
        }
        var proxyProtocol = ProxyType.wstunnel
        var remoteAddress = ip1
        if proto == stealth {
            proxyProtocol = .stunnel
            remoteAddress = ip3
        }
        return ProxyInfo(remoteServer: remoteAddress, remotePort: port, proxyType: proxyProtocol)
    }

    private func editOpenVPNConfig(proto: String, serverAddress: String, port: String, x509Name: String, proxyInfo: ProxyInfo?, userSettings: VPNUserSettings) throws -> (String, Data) {
        let protoLine = "proto \(proto.lowercased())"
        let remoteLine = "remote \(serverAddress) \(port)"
        let x509NameLine = "verify-x509-name \(x509Name) name"
        let proxyLine = proxyInfo?.text
        self.logger.logD( OpenVPNManager.self, proxyLine?.debugDescription ?? "")
        guard let configData = fileDatabase.readFile(path: FilePaths.openVPN),
              let stringData = String(data: configData,
                                      encoding: String.Encoding.utf8) else {
            throw VPNConfigurationErrors.invalidServerConfig
        }
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
        guard let appendedConfigData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else {
            throw VPNConfigurationErrors.invalidServerConfig
        }

        fileDatabase.removeFile(path: FilePaths.openVPN)
        fileDatabase.saveFile(data: appendedConfigData,
                              path: FilePaths.openVPN)
        return (FilePaths.openVPN, appendedConfigData)
    }

    private func getLocation(id: String) throws -> (Server, Group) {
        guard let servers = localDatabase.getServers() else { throw VPNConfigurationErrors.locationNotFound(id) }
        var serverResult: Server?
        var groupResult: Group?
        for server in servers {
            let groups = server.groups
            for group in groups where "\(group.id)" == id {
                serverResult = server
                groupResult = group
            }
        }
        guard let serverResultSafe = serverResult, let groupResultSafe = groupResult else { throw VPNConfigurationErrors.locationNotFound(id)
        }
        return (serverResultSafe, groupResultSafe)
    }

    private func getStaticIPLocation(id: String) throws -> StaticIP {
        let ipId = getId(location: id)
        guard let location = localDatabase.getStaticIPs()?.first(where: {"\($0.ipId)" == ipId}) else {
            throw VPNConfigurationErrors.locationNotFound(id)
        }
        return location
    }

    private func getId(location: String) -> String {
        let parts = location.split(separator: "-")
        if parts.count == 0 {
            return location
        }
        return parts[1].lowercased()
    }

    private func getLocationType(id: String) throws -> LocationType {
        let parts = id.split(separator: "-")
        if parts.count == 1 {
            return LocationType.server
        }
        let prefix = parts[0]
        if prefix == "static" {
            return LocationType.staticIP
        } else if prefix == "custom" {
            return LocationType.custom
        }
        // Should never happen
        throw VPNConfigurationErrors.invalidLocationType
    }

    private func getRandomNode(group: Group) throws -> Node {
        let nodes = group.nodes.toArray()
        if nodes.isEmpty {
            throw VPNConfigurationErrors.noValidNodeFound
        } else {
            // Always pick node with forced node option.
            let forceNode = advanceRepository.getForcedNode()
            if let forceNode = forceNode, let node = nodes.first(where: {$0.hostname == forceNode}) {
                return node
            }
            // Locations may be under maintence.
            let validNodes = nodes.filter { $0.forceDisconnect == false }
            // Pick random node with least amount of connections.
            var weightCounter = nodes.reduce(0, { $0 + $1.weight })
            if weightCounter >= 1 {
                let randomNumber = arc4random_uniform(UInt32(weightCounter))
                weightCounter = 0
                for node in validNodes {
                    weightCounter += node.weight
                    if randomNumber < weightCounter {
                        return node
                    }
                }
            }
            guard let randomNode = validNodes.randomElement() else {
                throw VPNConfigurationErrors.noValidNodeFound
            }
            return randomNode
        }
    }
}

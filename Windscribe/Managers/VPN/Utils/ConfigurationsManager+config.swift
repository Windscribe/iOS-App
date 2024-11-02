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
    func buildConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) async throws -> VPNConfiguration {
        let locationType = try getLocationType(id: location)
        if locationType == .custom {
            let locationId = getId(location: location)
            do {
                return try wgConfigFromCustomConfig(locationID: locationId)
            } catch {
                return try openConfigFromCustomConfig(locationID: locationId)
            }
        }
        if [udp, tcp, stealth, wsTunnel].contains(proto) {
            return try buildOpenVPNConfig(location: location, proto: proto, port: port, userSettings: userSettings)
        } else if proto == TextsAsset.iKEv2 {
            return try buildIKEv2Config(location: location)
        } else {
            return try await buildWgConfig(location: location, port: port)
        }
    }

    private func wgConfigFromCustomConfig(locationID: String) throws -> WireguardVPNConfiguration {
        let configFilePath = "\(locationID).conf"
        return try wgConfigurationFromPath(path: configFilePath)
    }

    func getProtoFromConfig(locationId: String) -> String? {
        if let _ = try? wgConfigFromCustomConfig(locationID: "\(locationId)") {
            return TextsAsset.wireGuard
        }
        if let config = try? openConfigFromCustomConfig(locationID: "\(locationId)") {
            return config.proto
        }
        return nil
    }

    private func openConfigFromCustomConfig(locationID: String) throws -> OpenVPNConfiguration {
        let configFilePath = "\(locationID).ovpn"
        guard let configData = fileDatabase.readFile(path: configFilePath) else {
            throw VPNConfigurationErrors.configNotFound
        }
        guard let config = localDatabase.getCustomConfigs().first(where: { $0.id == locationID })?.getModel() else {
            throw VPNConfigurationErrors.configNotFound
        }
        return OpenVPNConfiguration(proto: config.protocolType ?? udp, ip: config.serverAddress ?? "", username: config.username?.base64Decoded(), password: config.password?.base64Decoded(), path: configFilePath, data: configData)
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
            let node = try getRandomNode(nodes: location.1.nodes.toArray())
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
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
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
            let username = credentials.username.base64Decoded()
            let password = credentials.password.base64Decoded()
            keychainDb.save(username: username, password: password)
            let location = try getLocation(id: location)
            let node = try getRandomNode(nodes: location.1.nodes.toArray())
            let ip = node.ip
            let hostname = node.hostname
            guard let auth = keychainDb.retrieve(username: username) else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.iKEv2)
            }
            return IKEv2VPNConfiguration(username: username, auth: auth, hostname: hostname, ip: ip)
        case .staticIP:
            let location = try getStaticIPLocation(id: location)
            let node = try getRandomNode(nodes: location.nodes.toArray())
            let ip = node.ip
            let hostname = node.hostname
            guard let credentials = location.credentials.last else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.iKEv2)
            }
            let username = credentials.username
            let password = credentials.password
            keychainDb.save(username: username, password: password)
            guard let auth = keychainDb.retrieve(username: username) else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.iKEv2)
            }
            return IKEv2VPNConfiguration(username: username, auth: auth, hostname: hostname, ip: ip)
        default:
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
        }
    }

    private func buildOpenVPNConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) throws -> OpenVPNConfiguration {
        let locationID = getId(location: location)
        switch try getLocationType(id: location) {
        case .server:
            guard let credentials = localDatabase.getOpenVPNServerCredentials() else { throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN) }
            let username = credentials.username.base64Decoded()
            let password = credentials.password.base64Decoded()
            keychainDb.save(username: username, password: password)
            let location = try getLocation(id: location)
            let node = try getRandomNode(nodes: location.1.nodes.toArray())
            let proxyInfo = getProxyInfo(proto: proto, port: port, ip1: node.ip, ip3: node.ip3)
            let hostname = node.ip2
            let config = try editOpenVPNConfig(proto: proto, serverAddress: hostname, port: port, x509Name: location.1.ovpnX509, proxyInfo: proxyInfo, userSettings: userSettings)
            return OpenVPNConfiguration(proto: proto, ip: hostname, username: username, password: password, path: config.0, data: config.1)
        case .staticIP:
            let location = try getStaticIPLocation(id: locationID)
            let node = try getRandomNode(nodes: location.nodes.toArray())
            guard let credentials = location.credentials.last else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN)
            }
            let username = credentials.username
            let password = credentials.password
            keychainDb.save(username: username, password: password)
            let proxyInfo = getProxyInfo(proto: proto, port: port, ip1: node.ip, ip3: node.ip3)
            let hostname = node.ip2
            let config = try editOpenVPNConfig(proto: proto, serverAddress: hostname, port: port, x509Name: location.ovpnX509, proxyInfo: proxyInfo, userSettings: userSettings)
            return OpenVPNConfiguration(proto: proto, ip: node.hostname, username: username, password: password, path: config.0, data: config.1)
        default:
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
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
        var protoLine = "proto \(proto.lowercased())"
        if [stealth, wsTunnel].contains(proto) {
            protoLine = "proto tcp"
        }
        let remoteLine = "remote \(serverAddress) \(port)"
        let x509NameLine = "verify-x509-name \(x509Name) name"
        let proxyLine = proxyInfo?.text
        logger.logD(OpenVPNManager.self, proxyLine?.debugDescription ?? "")
        guard let configData = fileDatabase.readFile(path: FilePaths.openVPN),
              let stringData = String(data: configData,
                                      encoding: String.Encoding.utf8)
        else {
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
            for group in groups where id == "\(group.id)" {
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
        guard let location = localDatabase.getStaticIPs()?.first(where: { ipId == "\($0.ipId)" }) else {
            throw VPNConfigurationErrors.locationNotFound(id)
        }
        return location
    }

    private func getId(location: String) -> String {
        let parts = location.split(separator: "_")
        if parts.count == 1 {
            return location
        }
        return String(parts[1])
    }

    private func getLocationType(id: String) throws -> LocationType {
        let parts = id.split(separator: "_")
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

    private func getRandomNode(nodes: [Node]) throws -> Node {
        if nodes.isEmpty {
            throw VPNConfigurationErrors.noValidNodeFound
        } else {
            // Always pick node with forced node option.
            let forceNode = advanceRepository.getForcedNode()
            if let forceNode = forceNode, let node = nodes.first(where: { $0.hostname == forceNode }) {
                return node
            }
            // Locations may be under maintence.
            let validNodes = nodes.filter { $0.forceDisconnect == false }
            // Pick random node with least amount of connections.
            var weightCounter = nodes.reduce(0) { $0 + $1.weight }
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

//
//  ConfigurationsManager+config.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-30.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation
import Swinject
import WireGuardKit

extension ConfigurationsManager {
    /// Builds the appropriate VPN configuration based on location, location type, protocol, and port.
    func buildConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) async throws -> VPNConfiguration {
        guard let locationType = locationsManager.getLocationType(id: location) else {
            throw VPNConfigurationErrors.invalidLocationType
        }
        // If location type is custom config, proto/port does not matter just use whats in the profile.
        if locationType == .custom {
            let locationId = locationsManager.getId(location: location)
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
            return try await buildWgConfig(location: location, port: port, vpnSettings: userSettings)
        }
    }

    /// Builds WireGuard configuration from a custom  config's location id..
    private func wgConfigFromCustomConfig(locationID: String) throws -> WireguardVPNConfiguration {
        let configFilePath = "\(locationID).conf"
        return try wgConfigurationFromPath(path: configFilePath)
    }

    /// Gets the protocol type from the stored configuration based on location ID.
    func getProtoFromConfig(locationId: String) -> String? {
        if let _ = try? wgConfigFromCustomConfig(locationID: "\(locationId)") {
            return TextsAsset.wireGuard
        }
        if let config = try? openConfigFromCustomConfig(locationID: "\(locationId)") {
            return config.proto
        }
        return nil
    }

    /// Buildsn OpenVPN configuration from a custom config location.
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

    /// Loads a WireGuard configuration from a file path.
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

    /// Builds WireGuard configuration for a location based on its type.
    private func buildWgConfig(location: String, port: String, vpnSettings: VPNUserSettings) async throws -> WireguardVPNConfiguration {
        guard let locationType = locationsManager.getLocationType(id: location) else {
            throw VPNConfigurationErrors.invalidLocationType
        }
        switch locationType {
        case .server:
            let location = try locationsManager.getLocation(from: location)
            let node = try getRandomNode(nodes: location.1.nodes.toArray())
            let ip = node.ip3
            let hostname = node.hostname
            let publickey = location.1.wgPublicKey
            try await updateWireguardConfig(ip: ip, hostname: hostname, serverPublicKey: publickey, port: port, vpnSettings: vpnSettings)
            return try wgConfigurationFromPath(path: FilePaths.wireGuard)

        case .staticIP:
            let location = try getStaticIPLocation(id: location)
            guard let node = location.nodes.toArray().randomElement() else {
                throw VPNConfigurationErrors.noValidNodeFound
            }
            let ip = location.wgIp
            let hostname = node.hostname
            let publickey = location.wgPublicKey
            try await updateWireguardConfig(ip: ip, hostname: hostname, serverPublicKey: publickey, port: port, vpnSettings: vpnSettings)
            return try wgConfigurationFromPath(path: FilePaths.wireGuard)

        default:
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
        }
    }

    /// Gets Wireguard configuration from Api and saves to file.
    private func updateWireguardConfig(ip: String, hostname: String, serverPublicKey: String, port: String, vpnSettings: VPNUserSettings) async throws {
        wgCredentials.setNodeToConnect(serverEndPoint: ip, serverHostName: hostname, serverPublicKey: serverPublicKey, port: port)
        wgCredentials.deleteOldestKey = vpnSettings.deleteOldestKey
        return try await wgRepository.getCredentials().value
    }

    /// Creates an IKEv2 VPN configuration for the specified location.
    private func buildIKEv2Config(location: String) throws -> IKEv2VPNConfiguration {
        guard let locationType = locationsManager.getLocationType(id: location) else {
            throw VPNConfigurationErrors.invalidLocationType
        }
        switch locationType {
        case .server:
            guard let credentials = localDatabase.getIKEv2ServerCredentials() else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.iKEv2)
            }
            let username = credentials.username.base64Decoded()
            let password = credentials.password.base64Decoded()
            keychainDb.save(username: username, password: password)
            let location = try locationsManager.getLocation(from: location)
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

    /// Constructs an OpenVPN configuration using location, protocol, port, and user preferences.
    private func buildOpenVPNConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) throws -> OpenVPNConfiguration {
        let locationID = locationsManager.getId(location: location)
        guard let locationType = locationsManager.getLocationType(id: location) else {
            throw VPNConfigurationErrors.invalidLocationType
        }
        switch locationType {
        case .server:
            guard let credentials = localDatabase.getOpenVPNServerCredentials() else { throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN) }
            let username = credentials.username.base64Decoded()
            let password = credentials.password.base64Decoded()
            keychainDb.save(username: username, password: password)
            let location = try locationsManager.getLocation(from: location)
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

    /// Builds proxy info for OpenVPN if protocols is stealth or wstunnel.
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

    /**
     Edits the OpenVPN configuration server config with the specified parameters.
     - Parameters:
     - proto: The protocol to be used for the OpenVPN connection (e.g., "udp" or "tcp"). The protocol will be converted to lowercase.
     - serverAddress: Ip address of the node.
     - port: The port number for the OpenVPN connection.
     - x509Name: The X.509 certificate name for verification.
     - proxyInfo: An optional `ProxyInfo` object containing proxy settings. If nil, no proxy configuration will be added.
     - userSettings: A `VPNUserSettings` object containing user-specific settings, such as whether to enable censorship circumvention.

     - Throws:
     - `VPNConfigurationErrors.invalidServerConfig`: Thrown if the OpenVPN configuration file cannot be read or if an invalid server configuration is detected.

     - Returns: A tuple containing:
     - The path to the OpenVPN configuration file.
     - The modified configuration data as `Data`.
     If the existing configuration file does not contain the protocol, remote, or x509 settings, they are added at specified positions in the configuration file.
     */
    private func editOpenVPNConfig(proto: String, serverAddress: String, port: String, x509Name: String, proxyInfo: ProxyInfo?, userSettings: VPNUserSettings) throws -> (String, Data) {
        var protoLine = "proto \(proto.lowercased())"
        if [stealth, wsTunnel].contains(proto) {
            protoLine = "proto tcp"
        }
        let remoteLine = "remote \(serverAddress) \(port)"
        let x509NameLine = "verify-x509-name \(x509Name) name"
        let proxyLine = proxyInfo?.text
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

    /// Gets static ip location from database.
    private func getStaticIPLocation(id: String) throws -> StaticIP {
        let ipId = locationsManager.getId(location: id)
        guard let location = localDatabase.getStaticIPs()?.first(where: { ipId == "\($0.id)" }) else {
            throw VPNConfigurationErrors.locationNotFound(id)
        }
        return location
    }

    /// Selects a random node from the provided list of nodes, considering specific constraints and preferences.
    ///
    /// - Parameters:
    ///   - nodes: An array of `Node` objects representing server or static ip location.
    ///
    /// - Throws:
    ///   - `VPNConfigurationErrors.noValidNodeFound` if there are no nodes available to select from.
    /// - Discussion:
    ///   The selection logic prioritizes any user-specified forced node. If not applicable, it filters nodes under
    ///   maintenance and then uses weighted random selection. This ensures that nodes with fewer connections or lowers weight are
    ///   chosen more frequently, balancing load across nodes. If no weighted selection is possible, it falls back
    ///   to a purely random selection. This function guarantees that a valid node is selected, if available.
    private func getRandomNode(nodes: [Node]) throws -> Node {
        if nodes.isEmpty {
            throw VPNConfigurationErrors.noValidNodeFound
        } else {
            let forceNode = advanceRepository.getForcedNode()
            if let forceNode = forceNode, let node = nodes.first(where: { $0.hostname == forceNode }) {
                return node
            }
            let validNodes = nodes.filter { $0.forceDisconnect == false }
            var weightCounter = nodes.reduce(0) { $0 + $1.weight }
            if weightCounter >= 1 {
                let randomNumber = Int.random(in: 0 ..< Int(weightCounter))
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

    @MainActor
    func validateLocation(lastLocation: String) async throws -> String? {
        do {
            let locationID = locationsManager.getId(location: lastLocation)
            guard let locationType = locationsManager.getLocationType(id: locationID) else {
                throw VPNConfigurationErrors.invalidLocationType
            }

            switch locationType {
            case .server:
                let location = try locationsManager.getLocation(from: locationID)
                let isFreeUser = localDatabase.getSessionSync()?.isPremium == false
                if isFreeUser, location.1.premiumOnly {
                    throw VPNConfigurationErrors.invalidLocationType
                }
                _ = try getRandomNode(nodes: location.1.nodes.toArray())
                return lastLocation
            case .staticIP:
                let location = try getStaticIPLocation(id: locationID)
                _ = try getRandomNode(nodes: location.nodes.toArray())
                return lastLocation
            case .custom:
                do {
                    _ = try wgConfigFromCustomConfig(locationID: locationID)
                } catch {
                    _ = try openConfigFromCustomConfig(locationID: locationID)
                }
                return lastLocation
            }
        } catch {
            let updatedLocation = handleLocationFallback(for: lastLocation)
            logger.logD("VPNConfiguration", "Updated location to \(updatedLocation ?? "n/a")")
            return updatedLocation
        }
    }

    private func handleLocationFallback(for location: String) -> String? {
        let locationID = locationsManager.getId(location: location)
        logger.logD("VPNConfiguration", "Looking for fallback location for \(location)")
        guard let servers = localDatabase.getServers() else { return nil }

        var groupResult: GroupModel?
        for server in servers.map({ $0.getServerModel() }) {
            for group in server?.groups ?? [] where locationID == "\(group.id ?? 0)" {
                groupResult = server?.groups?.filter { $0.isNodesAvailable() }.randomElement()
            }
        }
        if let city = groupResult {
            return "\(city.id ?? 0)"
        } else {
            let bestLocation = locationsManager.getBestLocation()
            if !bestLocation.isEmpty {
                return bestLocation
            }
        }

        return nil
    }

    func validateAccessToLocation(locationID: String, isEmergency: Bool = false) -> Future<Void, Error> {
        return Future { promise in
            do {
                // if it's an emergency connect we should not validate access to the location
                guard !isEmergency else {
                    promise(.success(()))
                    return
                }
                if !(self.preferences.getPrivacyPopupAccepted() ?? false) {
                    promise(.failure(VPNConfigurationErrors.privacyNotAccepted))
                    return
                }
                guard let locationType = self.locationsManager.getLocationType(id: locationID) else {
                    throw VPNConfigurationErrors.invalidLocationType
                }
                switch locationType {
                case .server:
                    let location = try self.locationsManager.getLocation(from: locationID)
                    let isFreeUser = self.localDatabase.getSessionSync()?.isPremium == false
                    if isFreeUser, location.1.premiumOnly {
                        promise(.failure(VPNConfigurationErrors.upgradeRequired))
                    } else {
                        promise(.success(()))
                    }
                default:
                    promise(.success(()))
                }
            } catch {
                promise(.failure(error))
            }
        }
    }
}

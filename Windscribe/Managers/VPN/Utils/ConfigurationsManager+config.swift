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
        // Detect protocol change and clear failed servers to give new protocol a fresh start
        // This allows protocol failover to try the same servers that failed with previous protocols
        if currentConnectionProtocol != proto {
            if !currentConnectionProtocol.isEmpty && !failedServerHostnames.isEmpty {
                logger.logI("ConfigurationsManager", "Protocol changed from \(currentConnectionProtocol) to \(proto) - clearing \(failedServerHostnames.count) failed servers for fresh start")
                clearFailedServers()
            }
            currentConnectionProtocol = proto
        }

        guard let connectionTargetType = locationsManager.getConnectionTargetType(id: location) else {
            throw VPNConfigurationErrors.invalidConnectionTargetType
        }
        // If location type is custom config, proto/port does not matter just use whats in the profile.
        if connectionTargetType == .custom {
            let locationId = String(locationsManager.getCustomId(location: location))
            do {
                return try await wgConfigFromCustomConfig(locationId: locationId)
            } catch {
                return try await openConfigFromCustomConfig(locationID: locationId)
            }
        }
        if VPNProtocolType.openVPNIdentifiers.contains(proto) {
            return try await buildOpenVPNConfig(location: location, proto: proto, port: port, userSettings: userSettings)
        } else if proto == VPNProtocolType.iKEv2.identifier {
            return try buildIKEv2Config(location: location)
        } else {
            return try await buildWgConfig(location: location, port: port, vpnSettings: userSettings)
        }
    }

    /// Builds WireGuard configuration from a custom  config's location id..
    private func wgConfigFromCustomConfig(locationId: String) async throws -> WireguardVPNConfiguration {
        let configFilePath = "\(locationId).conf"
        return try await wgConfigurationFromPath(path: configFilePath)
    }

    /// Gets the protocol type from the stored configuration based on location ID.
    func getProtoFromConfig(locationId: String) async -> String? {
        do {
            _ = try await wgConfigFromCustomConfig(locationId: locationId)
            return VPNProtocolType.wireGuard.identifier
        } catch {
            do {
                let config = try await openConfigFromCustomConfig(locationID: locationId)
                return config.proto
            } catch {
                return nil
            }
        }
    }

    /// Buildsn OpenVPN configuration from a custom config location.
    private func openConfigFromCustomConfig(locationID: String) async throws -> OpenVPNConfiguration {
        let configFilePath = "\(locationID).ovpn"
        let configData: Data
        do {
            configData = try await fileDatabase.readFile(path: configFilePath)
        } catch FileDatabaseError.fileNotFound {
            throw VPNConfigurationErrors.configNotFound
        } catch {
            logger.logE("ConfigurationsManager", "Error reading custom config \(configFilePath): \(error.localizedDescription)")
            throw VPNConfigurationErrors.configNotFound
        }

        guard let config = customConfigRepository.getCustomConfig(fileId: locationID) else {
            throw VPNConfigurationErrors.configNotFound
        }
        let username = config.username.base64Decoded() == "" ? config.username : config.username.base64Decoded()
        let password = config.password.base64Decoded() == "" ? config.password : config.password.base64Decoded()

        // Clear credentials from database if saveCredentials is false
        if !config.saveCredentials && (!config.username.isEmpty || !config.password.isEmpty) {
            logger.logI("ConfigurationsManager", "Clearing credentials for custom config \(config.id) after building config (saveCredentials=false)")
            var updatedConfig = config
            updatedConfig.username = ""
            updatedConfig.password = ""
            customConfigRepository.saveCustomConfig(customConfig: updatedConfig)
        }

        return OpenVPNConfiguration(proto: config.protocolType, ip: config.serverAddress, username: username, password: password, path: configFilePath, data: configData)
    }

    /// Loads a WireGuard configuration from a file path.
    private func wgConfigurationFromPath(path: String) async throws -> WireguardVPNConfiguration {
        let configData: Data
        do {
            configData = try await fileDatabase.readFile(path: path)
        } catch FileDatabaseError.fileNotFound {
            throw VPNConfigurationErrors.configNotFound
        } catch {
            logger.logE("ConfigurationsManager", "Error reading WireGuard config \(path): \(error.localizedDescription)")
            throw VPNConfigurationErrors.configNotFound
        }
        guard let stringData = String(data: configData, encoding: String.Encoding.utf8) else {
            throw VPNConfigurationErrors.configNotFound
        }
        let tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: stringData, called: VPNProtocolType.wireGuard.identifier)
        return WireguardVPNConfiguration(content: tunnelConfiguration)
    }

    /// Builds WireGuard configuration for a location based on its type.
    private func buildWgConfig(location: String, port: String, vpnSettings: VPNUserSettings) async throws -> WireguardVPNConfiguration {
        guard let connectionTargetType = locationsManager.getConnectionTargetType(id: location) else {
            throw VPNConfigurationErrors.invalidConnectionTargetType
        }
        switch connectionTargetType {
        case .server:
            let locationDatacenter = try locationsManager.getLocationDatacenter(from: location)
            let server = try geServerFrom(datacenterId: locationDatacenter.1.id)
            let ip = server.ip3
            let hostname = server.hostname
            let publickey = locationDatacenter.1.wgPubkey
            locationListRepository.saveLastConnectedHost(for: hostname, with: locationDatacenter.1.id)
            try await updateWireguardConfig(ip: ip, hostname: hostname, serverPublicKey: publickey, port: port, ipv6: server.ipv6, vpnSettings: vpnSettings)
            return try await wgConfigurationFromPath(path: FilePaths.wireGuard)

        case .staticIP:
            let locationId = locationsManager.getLastConnectionTargetId(location: location)
            let staticLocation = try getStaticIPLocation(id: locationId)
            guard let node = Array(staticLocation.nodes).randomElement() else {
                throw VPNConfigurationErrors.noValidServerFound
            }
            let ip = staticLocation.wgIp
            let hostname = node.hostname
            let publickey = staticLocation.wgPublicKey
            locationListRepository.saveLastConnectedHost(for: hostname, with: locationId)
            try await updateWireguardConfig(ip: ip, hostname: hostname, serverPublicKey: publickey, port: port, ipv6: 0, vpnSettings: vpnSettings)
            return try await wgConfigurationFromPath(path: FilePaths.wireGuard)

        default:
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
        }
    }

    /// Gets Wireguard configuration from Api and saves to file.
    private func updateWireguardConfig(ip: String, hostname: String, serverPublicKey: String, port: String, ipv6: Int, vpnSettings: VPNUserSettings) async throws {
        wgCredentials.setNodeToConnect(serverEndPoint: ip, serverHostName: hostname, serverPublicKey: serverPublicKey, port: port, ipv6: ipv6)
        wgCredentials.deleteOldestKey = vpnSettings.deleteOldestKey
        return try await wgRepository.getCredentials()
    }

    /// Creates an IKEv2 VPN configuration for the specified location.
    private func buildIKEv2Config(location: String) throws -> IKEv2VPNConfiguration {
        guard let connectionTargetType = locationsManager.getConnectionTargetType(id: location) else {
            throw VPNConfigurationErrors.invalidConnectionTargetType
        }
        switch connectionTargetType {
        case .server:
            guard let credentials = credentialsRepository.ikev2Crendentials else {
                throw VPNConfigurationErrors.credentialsNotFound(VPNProtocolType.iKEv2.identifier)
            }
            let username = credentials.username.base64Decoded()
            let password = credentials.password.base64Decoded()
            keychainDb.save(username: username, password: password)
            let locationId = locationsManager.getLastConnectionTargetId(location: location)
            let locationDatacenter = try locationsManager.getLocationDatacenter(from: locationId)
            let server = try geServerFrom(datacenterId: locationDatacenter.1.id)
            let ip = server.ip
            let hostname = server.hostname
            locationListRepository.saveLastConnectedHost(for: hostname, with: locationDatacenter.1.id)
            guard let auth = keychainDb.retrieve(username: username) else {
                throw VPNConfigurationErrors.credentialsNotFound(VPNProtocolType.iKEv2.identifier)
            }
            return IKEv2VPNConfiguration(username: username, auth: auth, hostname: hostname, ip: ip)
        case .staticIP:
            let locationID = locationsManager.getLastConnectionTargetId(location: location)
            let staticLocation = try getStaticIPLocation(id: locationID)
            guard let node = Array(staticLocation.nodes).randomElement() else {
                throw VPNConfigurationErrors.noValidServerFound
            }
            let ip = node.ip1
            let hostname = node.hostname
            locationListRepository.saveLastConnectedHost(for: hostname, with: locationID)
            guard let credentials = staticLocation.credentials.last else {
                throw VPNConfigurationErrors.credentialsNotFound(VPNProtocolType.iKEv2.identifier)
            }
            let username = credentials.username
            let password = credentials.password
            keychainDb.save(username: username, password: password)
            guard let auth = keychainDb.retrieve(username: username) else {
                throw VPNConfigurationErrors.credentialsNotFound(VPNProtocolType.iKEv2.identifier)
            }
            return IKEv2VPNConfiguration(username: username, auth: auth, hostname: hostname, ip: ip)
        default:
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
        }
    }

    /// Constructs an OpenVPN configuration using location, protocol, port, and user preferences.
    private func buildOpenVPNConfig(location: String, proto: String, port: String, userSettings: VPNUserSettings) async throws -> OpenVPNConfiguration {
        let locationId = locationsManager.getLastConnectionTargetId(location: location)
        guard let connectionTargetType = locationsManager.getConnectionTargetType(id: location) else {
            throw VPNConfigurationErrors.invalidConnectionTargetType
        }
        switch connectionTargetType {
        case .server:
            guard let credentials = credentialsRepository.openVPNCrendentials else { throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN) }
            let username = credentials.username.base64Decoded()
            let password = credentials.password.base64Decoded()
            keychainDb.save(username: username, password: password)
            let locationDatacenter = try locationsManager.getLocationDatacenter(from: location)
            let server = try geServerFrom(datacenterId: locationDatacenter.1.id)
            let proxyInfo = getProxyInfo(proto: proto, port: port, ip1: server.ip, ip3: server.ip3)
            let hostname = server.hostname
            let serverAddress = server.ip2
            locationListRepository.saveLastConnectedHost(for: hostname, with: locationDatacenter.1.id)
            let config = try await editOpenVPNConfig(proto: proto, serverAddress: serverAddress, port: port, x509Name: locationDatacenter.1.ovpnX509, proxyInfo: proxyInfo, userSettings: userSettings)
            return OpenVPNConfiguration(proto: proto, ip: serverAddress, username: username, password: password, path: config.0, data: config.1)
        case .staticIP:
            let staticLocation = try getStaticIPLocation(id: locationId)
            guard let node = Array(staticLocation.nodes).randomElement() else {
                throw VPNConfigurationErrors.noValidServerFound
            }
            guard let credentials = staticLocation.credentials.last else {
                throw VPNConfigurationErrors.credentialsNotFound(TextsAsset.openVPN)
            }
            let username = credentials.username
            let password = credentials.password
            keychainDb.save(username: username, password: password)
            let proxyInfo = getProxyInfo(proto: proto, port: port, ip1: node.ip1, ip3: node.ip3)
            let hostname = node.ip2
            locationListRepository.saveLastConnectedHost(for: hostname, with: locationId)
            let config = try await editOpenVPNConfig(proto: proto, serverAddress: hostname, port: port, x509Name: staticLocation.ovpnX509, proxyInfo: proxyInfo, userSettings: userSettings)
            return OpenVPNConfiguration(proto: proto, ip: node.hostname, username: username, password: password, path: config.0, data: config.1)
        default:
            throw VPNConfigurationErrors.customConfigSupportNotAvailable
        }
    }

    /// Builds proxy info for OpenVPN if protocols is stealth or wstunnel.
    private func getProxyInfo(proto: String, port: String, ip1: String, ip3: String) -> ProxyInfo? {
        if !VPNProtocolType.proxiedOpenVPNIdentifiers.contains(proto) {
            return nil
        }
        var proxyProtocol = ProxyType.wstunnel
        var remoteAddress = ip1
        if proto == VPNProtocolType.stealth.identifier {
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
    private func editOpenVPNConfig(proto: String, serverAddress: String, port: String, x509Name: String, proxyInfo: ProxyInfo?, userSettings: VPNUserSettings) async throws -> (String, Data) {
        var protoLine = "proto \(proto.lowercased())"
        if VPNProtocolType.proxiedOpenVPNIdentifiers.contains(proto) {
            protoLine = "proto tcp"
        }
        let remoteLine = "remote \(serverAddress) \(port)"
        let x509NameLine = "verify-x509-name \(x509Name) name"
        let proxyLine = proxyInfo?.text
        let configData: Data
        do {
            configData = try await fileDatabase.readFile(path: FilePaths.openVPN)
        } catch FileDatabaseError.fileNotFound {
            throw VPNConfigurationErrors.invalidServerConfig
        } catch {
            logger.logE("ConfigurationsManager", "Error reading OpenVPN config: \(error.localizedDescription)")
            throw VPNConfigurationErrors.invalidServerConfig
        }

        guard let stringData = String(data: configData, encoding: String.Encoding.utf8) else {
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

        do {
            try? await fileDatabase.removeFile(path: FilePaths.openVPN)
            try await fileDatabase.saveFile(data: appendedConfigData, path: FilePaths.openVPN)
        } catch {
            logger.logE("ConfigurationsManager", "Failed to save modified OpenVPN config: \(error.localizedDescription)")
            throw VPNConfigurationErrors.invalidServerConfig
        }
        return (FilePaths.openVPN, appendedConfigData)
    }

    /// Gets static ip location from database.
    private func getStaticIPLocation(id: Int) throws -> StaticIPModel {
        guard let staticIP = staticIpRepository.getStaticIp(id: id) else {
            throw VPNConfigurationErrors.locationNotFound(String(id))
        }
        return staticIP
    }

    /// Selects a node from the group, checks is there is a pinned iP or a forced server, if not then
    /// gets a random server from the Datacenter Servers
    ///
    /// - Parameters:
    ///   - group: A `DatacenterModel` representeing the location the user is connecting to.
    ///
    /// - Throws:
    ///   - `VPNConfigurationErrors.noValidServerFound` if there are no servers available to select from.
    ///
    private func geServerFrom(datacenterId: Int) throws -> ServerMachineModel {
        let servers = locationListRepository.getServers(for: datacenterId)
        if servers.isEmpty {
            throw VPNConfigurationErrors.noValidServerFound
        } else {
            // Check if we have a forced node
            let forceHostname = advanceRepository.getForcedServer()
            if let forceHostname = forceHostname, let server = servers.first(where: { $0.hostname.areSubdomainsEqual(other: forceHostname) }) {
                logger.logI("ConfigurationsManager", "getNodeFrom returns node: \(server)")
                return server
            }

            // Check if we have a pinned ip for this location
            let pinnedHostName = locationListRepository.getDatacenterPinnedHotname(for: datacenterId)
            if let pinnedHostName = pinnedHostName,
               let pinnedNode = servers.first(where: { $0.hostname.areSubdomainsEqual(other: pinnedHostName)  }) {
                if !preferences.getIgnorePinIP() {
                    logger.logI("ConfigurationsManager", "getNodeFrom returns pinned node: \(pinnedHostName)")
                    return pinnedNode
                } else {
                    logger.logI("ConfigurationsManager", "Ignoring pinned IP preference, will select random node")
                }
            }

             logger.logI("ConfigurationsManager", "getNodeFrom found no pinned or forced node so trying random")
            return try getRandomServer(servers: servers)
        }
    }

    /// Selects a random node from the provided list of servers, considering specific constraints and preferences.
    ///
    /// - Parameters:
    ///   - servers: An array of `ServerMachineModel` objects representing server or static ip location.
    ///
    /// - Throws:
    ///   - `VPNConfigurationErrors.noValidServerFound` if there are no servers  available to select from.
    /// - Discussion:
    ///   The selection filters servers  under maintenance, excludes previously failed servers, and then uses weighted random selection.
    ///   This ensures that servers with fewer connections or lowers weight are
    ///   chosen more frequently, balancing load across servers. If no weighted selection is possible, it falls back
    ///   to a purely random selection. This function guarantees that a valid server is selected, if available.
    private func getRandomServer(servers: [ServerMachineModel]) throws -> ServerMachineModel {
        if servers.isEmpty {
            throw VPNConfigurationErrors.noValidServerFound
        } else {
            var copyServers = servers
            // Filter out all previously failed servers to avoid retry
            if !failedServerHostnames.isEmpty {
                let beforeCount = copyServers.count
                copyServers = copyServers.filter { !failedServerHostnames.contains($0.hostname) }
                let excludedCount = beforeCount - copyServers.count
                if excludedCount > 0 {
                    logger.logI("ConfigurationsManager", "Excluded \(excludedCount) failed servers from selection, \(copyServers.count) servers remaining")
                }
            }

            // If all servers exhausted after filtering, throw error to trigger protocol failover
            // This ensures the connection fails properly and allows ProtocolManager to try the next protocol
            guard !copyServers.isEmpty else {
                logger.logE("ConfigurationsManager", "No valid servers available in location")
                throw VPNConfigurationErrors.noValidServerFound
            }

            var weightCounter = copyServers.reduce(0) { $0 + $1.weight }
            if weightCounter >= 1 {
                let randomNumber = Int.random(in: 0 ..< Int(weightCounter))
                weightCounter = 0
                for server in copyServers {
                    weightCounter += server.weight
                    if randomNumber < weightCounter {
                        logger.logI("ConfigurationsManager", "getRandomNode returns calculated node: \(server)")
                        return server
                    }
                }
            }
            guard let randomServer = copyServers.randomElement() else {
                throw VPNConfigurationErrors.noValidServerFound
            }
            logger.logI("ConfigurationsManager", "getRandomNode returns random node: \(randomServer)")
            return randomServer
        }
    }

    @MainActor
    func validateLocation(lastLocation: String) async throws -> String? {
        do {
            let locationId = locationsManager.getLastConnectionTargetId(location: lastLocation)
            guard let connectionTargetType = locationsManager.getConnectionTargetType(id: lastLocation) else {
                throw VPNConfigurationErrors.invalidConnectionTargetType
            }

            switch connectionTargetType {
            case .server:
                let locationDatacenter = try locationsManager.getLocationDatacenter(from: locationId)
                let isFreeUser = userSessionRepository.sessionModel?.isPremium == false
                if isFreeUser, locationDatacenter.1.isPremiumOnly {
                    throw VPNConfigurationErrors.invalidConnectionTargetType
                }
                _ = try await geServerFrom(datacenterId: locationDatacenter.1.id)
                return lastLocation
            case .staticIP:
                let staticLocation = try await getStaticIPLocation(id: locationId)
                guard let _ = Array(staticLocation.nodes).randomElement() else {
                    throw VPNConfigurationErrors.noValidServerFound
                }
                return lastLocation
            case .custom:
                do {
                    _ = try await wgConfigFromCustomConfig(locationId: lastLocation)
                } catch {
                    _ = try await openConfigFromCustomConfig(locationID: lastLocation)
                }
                return lastLocation
            }
        } catch {
            let updatedLocation = await handleLocationFallback(for: lastLocation)
            logger.logI("VPNConfiguration", "Updated location to \(updatedLocation ?? "n/a")")
            return updatedLocation
        }
    }

    private func handleLocationFallback(for location: String) -> String? {
        let locationId = locationsManager.getLastConnectionTargetId(location: location)
        logger.logI("VPNConfiguration", "Looking for fallback location for \(location)")
        let locations = locationListRepository.currentLocationModels
        guard !locations.isEmpty else { return nil }
        let location = locations.first { $0.datacenters.first { locationId == $0.id } != nil }
        guard let safeLocation = location else { return nil }
        let datacenter = safeLocation.datacenters.filter { locationId != $0.id && !locationListRepository.getServers(for: locationId).isEmpty }
            .randomElement()
        if let safeDatacenter = datacenter {
            return String(safeDatacenter.id)
        } else {
            return String(locationsManager.getBestLocation())
        }
    }

    func validateAccessToLocation(locationID: String, connectionType: ConnectionType = .user) -> Future<Void, Error> {
        return Future { promise in
            do {
                // if it's an emergency connect we should not validate access to the location
                guard connectionType != .emergency else {
                    promise(.success(()))
                    return
                }
                if !(self.preferences.getPrivacyPopupAccepted() ?? false) {
                    promise(.failure(VPNConfigurationErrors.privacyNotAccepted))
                    return
                }
                guard let connectionTargetType = self.locationsManager.getConnectionTargetType(id: locationID) else {
                    throw VPNConfigurationErrors.invalidConnectionTargetType
                }
                switch connectionTargetType {
                case .server:
                    let location = try self.locationsManager.getLocationDatacenter(from: locationID)
                    let session = self.userSessionRepository.sessionModel
                    let isFreeUser = session?.isPremium == false

                    if session?.status == 2 {
                        promise(.failure(VPNConfigurationErrors.accountExpired))
                    } else if session?.status == 3 {
                        promise(.failure(VPNConfigurationErrors.accountBanned))
                    } else if isFreeUser {
                        if location.1.isPremiumOnly {
                            if !self.userSessionRepository.canAccesstoProLocation(location: location.0) {
                                promise(.failure(VPNConfigurationErrors.upgradeRequired))
                            } else {
                                promise(.success(()))
                            }
                        } else {
                            promise(.success(()))
                        }
                    } else {
                        promise(.success(()))
                    }
                case .custom:
                    let customId = self.locationsManager.getCustomId(location: locationID)
                    guard let customConfig = self.customConfigRepository.getCustomConfig(fileId: customId) else {
                        promise(.failure(VPNConfigurationErrors.customConfigSupportNotAvailable))
                        return
                    }
                    if (customConfig.username == "" || customConfig.password == "") && (customConfig.authRequired) {
                        promise(.failure(VPNConfigurationErrors.customConfigMissingCredentials(customConfig)))
                        return
                    }
                    promise(.success(()))
                default:
                    promise(.success(()))
                }
            } catch {
                promise(.failure(error))
            }
        }
    }
}

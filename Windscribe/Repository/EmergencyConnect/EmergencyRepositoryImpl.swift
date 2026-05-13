//
//  EmergencyRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation

class EmergencyRepositoryImpl: EmergencyRepository {
    private let wsnetEmergencyConnect: WSNetEmergencyConnectType
    private let vpnManager: VPNManager
    private let vpnStateRepository: VPNStateRepository
    private let fileDatabase: FileDatabase
    private let logger: FileLogger
    private let locationsManager: LocationsManager
    private let protocolManager: ProtocolManagerType
    private let customConfigRepository: CustomConfigRepository
    private let configuationName = AppConstants.emergencyConfig

    init(wsnetEmergencyConnect: WSNetEmergencyConnectType,
         vpnManager: VPNManager,
         vpnStateRepository: VPNStateRepository,
         fileDatabase: FileDatabase,
         logger: FileLogger,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType,
         customConfigRepository: CustomConfigRepository) {
        self.wsnetEmergencyConnect = wsnetEmergencyConnect
        self.vpnStateRepository = vpnStateRepository
        self.vpnManager = vpnManager
        self.fileDatabase = fileDatabase
        self.logger = logger
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
        self.customConfigRepository = customConfigRepository
    }

    /// Loads Emergency connect configurations from WSNet.
    func getConfig() async -> [OpenVPNConnectionInfo] {
        let endpoints = await wsnetEmergencyConnect.getIpEndpoints()
        let configs = endpoints.compactMap { endpoint -> OpenVPNConnectionInfo? in
            guard let config = self.wsnetEmergencyConnect.getOvpnConfig().utf8Encoded else {
                return nil
            }
            let ip = endpoint.ip()
            let port = String(endpoint.port())
            let proto = if endpoint.protocol() == 0 {
                VPNProtocolType.udp.identifier
            } else {
                VPNProtocolType.tcp.identifier
            }
            let username = self.wsnetEmergencyConnect.getUsername()
            let password = self.wsnetEmergencyConnect.getPassword()
            return OpenVPNConnectionInfo(serverConfig: config, ip: ip, port: port, protocolName: proto, username: username, password: password)
        }
        return configs
    }

    func isConnected() -> Bool {
        vpnStateRepository.isEmergencyConnection
    }

    func cleansEmergencyConfigs() {
        // First, remove the emergency configs from repository SYNCHRONOUSLY
        let emergencyConfigs = customConfigRepository.customConfigs.value.filter { config in
            config.name == configuationName
        }

        emergencyConfigs.forEach { config in
            customConfigRepository.removeCustomConfig(fileId: config.id)
        }

        // Then clear the location if it's pointing to an emergency custom config
        if locationsManager.getConnectionTargetType() == .custom {
            // Check if the current custom config is an emergency config
            let locationId = locationsManager.getLastConnectionTarget()
            let customId = locationsManager.getCustomId(location: locationId)
            let isEmergencyConfig = emergencyConfigs.contains { config in
                config.id == customId
            }

            if isEmergencyConfig {
                locationsManager.clearLastConnectionTarget()
                let bestLocation = locationsManager.getBestLocation()
                locationsManager.saveBestLocation(with: String(bestLocation))
            }
        }

        vpnStateRepository.setLastConnectionType(.user)

        // Finally, refresh protocols asynchronously
        Task {
            logger.logI("EmergencyRepository", "cleansEmergencyConfigs for getRefreshedProtocols")
            await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    // Stops tunnel
    func disconnect() -> AnyPublisher<VPNConnectionState, Error> {
        cleansEmergencyConfigs()
        return vpnManager.disconnectFromViewModel()
    }

    /// Configures OpenVPN and attempts a connection.
    func connect(configInfo: OpenVPNConnectionInfo) -> AnyPublisher<VPNConnectionState, Error> {
        Future<Data, Error> { promise in
            Task {
                do {
                    let data = try await self.buildConfiguration(configInfo: configInfo)
                    promise(.success(data))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .flatMap { data -> AnyPublisher<CustomConfigModel, Error> in
            Future<CustomConfigModel, Error> { promise in
                Task {
                    do {
                        let customConfig = try await self
                            .customConfigRepository
                            .saveOpenVPNCustomConfig(data: data,
                                                     configInfo: configInfo,
                                                     configuationName: self.configuationName)
                        self.locationsManager.saveCustomConfig(withId: customConfig.id)
                        promise(.success(customConfig))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { _ -> AnyPublisher<VPNConnectionState, Error> in
            Future<Void, Never> { promise in
                Task {
                    self.logger.logI("EmergencyRepository", "connect for getRefreshedProtocols")
                    await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                    promise(.success(()))
                }
            }
            .flatMap { _ -> AnyPublisher<VPNConnectionState, Error> in
                let nextProtocol = self.protocolManager.getProtocol()
                let locationID = self.locationsManager.getLastConnectionTarget()
                return self.vpnManager.connectFromViewModel(locationId: locationID, proto: nextProtocol, connectionType: .emergency)
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Builds OpenVPN Configuration from OpenVPNConnectionInfo
    private func buildConfiguration(configInfo: OpenVPNConnectionInfo) async throws -> Data {
        guard let stringData = String(data: configInfo.serverConfig, encoding: String.Encoding.utf8),
              !stringData.isEmpty else { throw RepositoryError.missingServerConfig }
        var lines = stringData.components(separatedBy: "\n")
        let protoLine = "proto \(configInfo.protocolName.lowercased())"
        let remoteLine = "remote \(configInfo.ip) \(configInfo.port)"
        var configFound = false
        for (index, line) in lines.enumerated() {
            if line.contains("proto ") {
                lines[index] = protoLine
                configFound = true
            }
            if line.contains("remote ") {
                lines[index] = remoteLine
                configFound = true
            }
            // Connection gets stuck in to reconnecting loop with this option.
            if line.starts(with: "ns-cert-type") {
                lines.remove(at: index)
            }
        }
        if configFound == false {
            lines.insert(protoLine, at: 2)
            lines.insert(remoteLine, at: 3)
        }
        if let config = lines.joined(separator: "\n").data(using: String.Encoding.utf8) {
            return config
        }
        throw RepositoryError.failedToTemplateOpenVPNConfig
    }
}

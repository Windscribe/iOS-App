//
//  EmergencyRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift

class EmergencyRepositoryImpl: EmergencyRepository {
    private let wsnetEmergencyConnect: WSNetEmergencyConnect
    private let vpnManager: VPNManager
    private let fileDatabase: FileDatabase
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let locationsManager: LocationsManagerType
    private let protocolManager: ProtocolManagerType
    private let disposeBag = DisposeBag()
    private let configuationName = "emergency-connect"

    init(wsnetEmergencyConnect: WSNetEmergencyConnect, vpnManager: VPNManager, fileDatabase: FileDatabase, localDatabase: LocalDatabase, logger: FileLogger, locationsManager: LocationsManagerType, protocolManager: ProtocolManagerType) {
        self.wsnetEmergencyConnect = wsnetEmergencyConnect
        self.vpnManager = vpnManager
        self.fileDatabase = fileDatabase
        self.localDatabase = localDatabase
        self.logger = logger
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    /// Loads Emergency connect configurations from WSNet.
    func getConfig() async -> [OpenVPNConnectionInfo] {
        let endpoints = await withCheckedContinuation { continuation in
            wsnetEmergencyConnect.getIpEndpoints { endpoints in
                continuation.resume(returning: endpoints)
            }
        }
        let configs = endpoints.map { endpoint in
            let config = self.wsnetEmergencyConnect.ovpnConfig().utf8Encoded
            let ip = endpoint.ip()
            let port = String(endpoint.port())
            let proto = if endpoint.protocol() == 0 {
                udp
            } else {
                tcp
            }
            let username = self.wsnetEmergencyConnect.username()
            let password = self.wsnetEmergencyConnect.password()
            return OpenVPNConnectionInfo(serverConfig: config, ip: ip, port: port, protocolName: proto, username: username, password: password)
        }
        return configs
    }

    func isConnected() -> Bool {
        return vpnManager.isConnected()
    }

    func cleansEmergencyConfigs() {
        if locationsManager.getLocationType() == .custom {
            locationsManager.clearLastSelectedLocation()
            let bestLocation = locationsManager.getBestLocation()
            locationsManager.saveBestLocation(with: bestLocation)
        }
        localDatabase.getCustomConfigs().filter { config in
            config.name == configuationName && config.isInvalidated == false
        }.forEach {
            localDatabase.removeCustomConfig(fileId: $0.id)
        }
    }

    // Stops tunnel
    func disconnect() -> AnyPublisher<VPNConnectionState, Error> {
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
        .map { data -> CustomConfig in
            let customConfig = self.saveConfiguration(data: data, configInfo: configInfo)
            self.locationsManager.saveCustomConfig(withID: customConfig.id)
            return customConfig
        }
        .flatMap { _ -> AnyPublisher<VPNConnectionState, Error> in
            Future<Void, Never> { promise in
                Task {
                    await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                    promise(.success(()))
                }
            }
            .flatMap { _ -> AnyPublisher<VPNConnectionState, Error> in
                let nextProtocol = self.protocolManager.getProtocol()
                let locationID = self.locationsManager.getLastSelectedLocation()
                return self.vpnManager.connectFromViewModel(locationId: locationID, proto: nextProtocol, connectionType: .emergency)
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Saves configuration as file and custom config model
    private func saveConfiguration(data: Data, configInfo: OpenVPNConnectionInfo) -> CustomConfig {
        let fileId = UUID().uuidString
        let path = "\(fileId).ovpn"
        fileDatabase.saveFile(data: data, path: path)
        let customConfig = CustomConfig(id: fileId, name: configuationName, serverAddress: configInfo.ip, protocolType: configInfo.protocolName, port: configInfo.port, username: configInfo.username, password: configInfo.password, authRequired: true)
        localDatabase.saveCustomConfig(customConfig: customConfig).disposed(by: disposeBag)
        return customConfig
    }

    /// Builds OpenVPN Configuration from OpenVPNConnectionInfo
    private func buildConfiguration(configInfo: OpenVPNConnectionInfo) async throws -> Data {
        guard let stringData = String(data: configInfo.serverConfig, encoding: String.Encoding.utf8) else { throw RepositoryError.missingServerConfig }
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

//
//  EmergencyRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class EmergencyRepositoryImpl: EmergencyRepository {
    private let wsnetEmergencyConnect: WSNetEmergencyConnect
    private let vpnManager: VPNManager
    private let fileDatabase: FileDatabase
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    private let configuationName = "emergency-connect"

    init(wsnetEmergencyConnect: WSNetEmergencyConnect, vpnManager: VPNManager, fileDatabase: FileDatabase, localDatabase: LocalDatabase, logger: FileLogger) {
        self.wsnetEmergencyConnect = wsnetEmergencyConnect
        self.vpnManager = vpnManager
        self.fileDatabase = fileDatabase
        self.localDatabase = localDatabase
        self.logger = logger
    }

    /// Loads Emergency connect configurations from WSNet.
    func getConfig() -> Single<[OpenVPNConnectionInfo]> {
        return Single<[OpenVPNConnectionInfo]>.create { callback in
            self.wsnetEmergencyConnect.getIpEndpoints { endpoints in
                let configs = endpoints.map { endpoint in
                    let config = self.wsnetEmergencyConnect.ovpnConfig().utf8Encoded
                    let ip = endpoint.ip()
                    let port = String(endpoint.port())
                    let proto = if endpoint.protocol() == 0 {
                        "udp"
                    } else {
                        "tcp"
                    }
                    let username = self.wsnetEmergencyConnect.username()
                    let password = self.wsnetEmergencyConnect.password()
                    return OpenVPNConnectionInfo(serverConfig: config, ip: ip, port: port, protocolName: proto, username: username, password: password)
                }
                callback(.success(configs))
            }
            return Disposables.create()
        }
    }

    func isConnected() -> Bool {
        return vpnManager.isConnected()
    }

    // Removes Emergency connect profile.
    func removeProfile() -> Completable {
        Completable.create { [self] completion in
            vpnManager.resetProfiles { [self] in
                vpnManager.resetProperties()
                Task {
                    await self.vpnManager.configManager.removeProfile(with: .openVPN, killSwitch: self.vpnManager.killSwitch)
                    completion(.completed)
                }
            }
            return Disposables.create()
        }
    }

    func cleansEmergencyConfigs() {
        // TODO: VPNManager cleansEmergencyConfigs
    }

    // Stops tunnel
    func disconnect() {
       // TODO: VPNManager Disconnect
    }

    /// Configures OpenVPN and attempts a connection.
    func connect(configInfo: OpenVPNConnectionInfo) -> Completable {
        // TODO: VPNManager connect
        return Completable.empty()
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

    /// Loads configuration in OpenVPNManager
    private func loadConfiguration(name: String, serverAddress: String, customConfig: CustomConfigModel) -> Completable {
        // TODO: VPNManager loadConfiguration
        return Completable.empty()
    }

    /// Builds OpenVPN Configuration from OpenVPNConnectionInfo
    private func buildConfiguration(configInfo: OpenVPNConnectionInfo) -> Single<Data> {
        guard let stringData = String(data: configInfo.serverConfig, encoding: String.Encoding.utf8) else { return Single.error(RepositoryError.missingServerConfig) }
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
            return Single.just(config)
        }
        return Single.error(RepositoryError.failedToTemplateOpenVPNConfig)
    }
}

//
//  CustomConfigRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-26.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

class CustomConfigRepositoryImpl: CustomConfigRepository {
    private let fileDatabase: FileDatabase
    private let localDatabase: LocalDatabase
    private let portMapRepository: PortMapRepository
    private let logger: FileLogger
    private let preferences: Preferences

    private var cancellables = Set<AnyCancellable>()
    var customConfigs = CurrentValueSubject<[CustomConfigModel], Never>([])

    init(fileDatabase: FileDatabase,
         localDatabase: LocalDatabase,
         logger: FileLogger,
         portMapRepository: PortMapRepository,
         preferences: Preferences) {
        self.fileDatabase = fileDatabase
        self.localDatabase = localDatabase
        self.logger = logger
        self.portMapRepository = portMapRepository
        self.preferences = preferences

        self.localDatabase.getCustomConfigPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] customConfig in
                guard let self = self else { return }
                let allCredentials = preferences.getAllCustomConfigCredentials()
                let models = customConfig.map { model -> CustomConfigModel in
                    var hydrated = model
                    if let credentials = allCredentials[model.id] {
                        self.loadCredentials(&hydrated, with: credentials)
                    }
                    return hydrated
                }
                self.customConfigs.send(models)
            })
            .store(in: &cancellables)
    }

    // MARK: - Credential Helpers (via Preferences)

    private func saveCredentials(_ config: CustomConfigModel) {
        let credentials = ServerCredentialsModel(username: config.username, password: config.password)
        preferences.saveCustomConfigCredentials(configId: config.id, credentials: credentials)
    }

    private func loadCredentials(_ config: inout CustomConfigModel) {
        if let credentials = preferences.getCustomConfigCredentials(configId: config.id) {
            loadCredentials(&config, with: credentials)
        }
    }


    private func loadCredentials(_ config: inout CustomConfigModel, with credentials: ServerCredentialsModel) {
        config.username = credentials.username
        config.password = credentials.password
    }

    private func deleteCredentials(configId: String) {
        preferences.deleteCustomConfigCredentials(configId: configId)
    }

    func saveOpenVPNCustomConfig(data: Data,
                                 configInfo: OpenVPNConnectionInfo,
                                 configuationName: String) async throws -> CustomConfigModel {
        let fileId = UUID().uuidString
        let path = "\(fileId).ovpn"

        // Async file operation
        try await fileDatabase.saveFile(data: data, path: path)

        // Build full model for caller, save credentials to Keychain, persist Realm row with empty creds.
        let configModel = CustomConfigModel(id: fileId, name: configuationName, serverAddress: configInfo.ip, protocolType: configInfo.protocolName, port: configInfo.port, username: configInfo.username, password: configInfo.password, authRequired: true, saveCredentials: true)
        saveCredentials(configModel)
        var realmModel = configModel
        realmModel.username = ""
        realmModel.password = ""
        localDatabase.saveCustomConfig(customConfig: realmModel)

        return configModel
    }

    func saveWgConfig(url: URL) async throws {
        logger.logI("CustomConfigRepositoryImpl", "Saving custom WireGuard config file.")
        do {
            var data = try Data(contentsOf: url)
            if let fileName = url.lastPathComponent.split(separator: ".").first {
                let serverName = String(fileName)
                let fileId = UUID().uuidString
                let path = "\(fileId).conf"
                guard let stringData = String(data: data, encoding: String.Encoding.utf8) else {
                    throw RepositoryError.invalidConfigData
                }

                let lines = stringData.components(separatedBy: "\n")
                var serverAddress = ""
                var port = ""
                for line in lines where line.contains("Endpoint = ") {
                    let endpoint = String(String(line.split(separator: "=")[1]).dropFirst(1))
                    let addressAndPort = endpoint.split(separator: ":")
                    serverAddress = String(addressAndPort[0])
                    port = String(addressAndPort[1])
                }
                if serverAddress == "" {
                    throw RepositoryError.invalidConfigData
                }
                guard let configData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else { throw RepositoryError.invalidConfigData }
                data = configData
                // Capture individual values for thread safety
                let configId = fileId
                let configName = serverName
                let configServerAddress = serverAddress
                let configProtocolType = VPNProtocolType.wireGuard.identifier
                let configPort = port

                do {
                    // File operation first (async)
                    try await fileDatabase.saveFile(data: data, path: path)

                    // Realm operation on main thread
                    let customConfig = CustomConfigModel(id: configId, name: configName, serverAddress: configServerAddress, protocolType: configProtocolType, port: configPort, saveCredentials: true)
                    localDatabase.saveCustomConfig(customConfig: customConfig)
                } catch {
                    logger.logE("CustomConfigRepositoryImpl", "Failed to save WG config file: \(error)")
                    throw RepositoryError.invalidConfigData
                }
            }
        } catch {
            logger.logE("CustomConfigRepositoryImpl", "Error when saving custom config file. \(error.localizedDescription)")
            throw RepositoryError.invalidConfigData
        }
    }

    func saveOpenVPNConfig(url: URL) async throws {
        logger.logI("CustomConfigRepositoryImpl", "Saving custom OpenVPN config file.")
        do {
            var data = try Data(contentsOf: url)
            if let fileName = url.lastPathComponent.split(separator: ".").first {
                let serverName = String(fileName)
                let fileId = UUID().uuidString
                let path = "\(fileId).ovpn"
                guard let stringData = String(data: data, encoding: String.Encoding.utf8) else { throw RepositoryError.invalidConfigData }

                var lines = stringData.components(separatedBy: "\n")
                var protocolType = ""
                var port = ""
                var serverAddress = ""
                var remoteLineNumber = 0
                var containsCert = false
                var authRequired = false
                var routeLines = [Int]()
                for (index, line) in lines.enumerated() {
                    if line.contains("proto ") {
                        protocolType = String(line.split(separator: " ")[1]).uppercased()
                        protocolType = String(protocolType.filter { !" \n\t\r".contains($0) })
                    }
                    if line.contains("remote ") {
                        remoteLineNumber = index
                        serverAddress = String(line.split(separator: " ")[1])
                        let remote = line.split(separator: " ")
                        if remote.indices.contains(2) {
                            port = String(remote[2].filter { !" \n\t\r".contains($0) })
                        }
                    }
                    if line.contains("<cert>") {
                        containsCert = true
                    }
                    if line.contains("auth-user-pass") {
                        authRequired = true
                    }
                    if line.contains("fragment") {
                        throw RepositoryError.invalidConfigData
                    }
                    if line.contains("route") {
                        routeLines.append(index)
                    }
                }
                for rLine in routeLines {
                    lines.remove(at: rLine)
                }
                if serverAddress == "" {
                    throw RepositoryError.invalidConfigData
                }
                if protocolType == "" {
                    protocolType = VPNProtocolType.iKEv2.identifier
                    lines.insert("proto \(protocolType.lowercased())", at: remoteLineNumber)
                }
                if port == "" {
                    guard let portsArray = portMapRepository.getPorts(protocolType: protocolType) else { throw RepositoryError.invalidConfigData }
                    port = portsArray[0]
                }

                if let configurationFileURL = Bundle.main.url(forResource: "cert", withExtension: "file"),
                   let configurationFileContent = try? Data(contentsOf: configurationFileURL),
                   !containsCert {
                    data.append(configurationFileContent)
                }

                guard let configData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else { throw RepositoryError.invalidConfigData }
                data = configData

                // Capture individual values for thread safety
                let configId = fileId
                let configName = serverName
                let configServerAddress = serverAddress
                let configProtocolType = protocolType
                let configPort = port
                let configAuthRequired = authRequired

                do {
                    // File operation first (async)
                    try await fileDatabase.saveFile(data: data, path: path)

                    // Realm operation on main thread
                    let customConfig = CustomConfigModel(id: configId, name: configName, serverAddress: configServerAddress, protocolType: configProtocolType, port: configPort, authRequired: configAuthRequired, saveCredentials: true)
                    localDatabase.saveCustomConfig(customConfig: customConfig)
                } catch {
                    logger.logE("CustomConfigRepositoryImpl", "Failed to save OpenVPN config file: \(error)")
                    throw RepositoryError.invalidConfigData
                }
            }
        } catch {
            logger.logE("CustomConfigRepositoryImpl", "Error when saving custom OpenVPN config file. \(error.localizedDescription)")
            throw RepositoryError.invalidConfigData
        }
    }

    func removeOpenVPNConfig(fileId: String) async {
        logger.logI("CustomConfigRepositoryImpl", "Removing custom OpenVPN config file.")
        try? await fileDatabase.removeFile(path: "\(fileId).ovpn")
        removeCustomConfig(fileId: fileId)
    }

    func removeWgConfig(fileId: String) async {
        logger.logI("CustomConfigRepositoryImpl", "Removing custom config file.")
        try? await fileDatabase.removeFile(path: "\(fileId).conf")
        removeCustomConfig(fileId: fileId)
    }

    func removeCustomConfig(fileId: String) {
        deleteCredentials(configId: fileId)
        localDatabase.removeCustomConfig(fileId: fileId)
        let allCredentials = preferences.getAllCustomConfigCredentials()
        let models = localDatabase.getCustomConfigs().map { model -> CustomConfigModel in
            var hydrated = model
            if let credentials = allCredentials[model.id] {
                self.loadCredentials(&hydrated, with: credentials)
            }
            return hydrated
        }
        customConfigs.send(models)
    }

    func getCustomConfig(fileId: String) -> CustomConfigModel? {
        guard var model = localDatabase.getCustomConfigs()
            .first(where: { fileId == $0.id }) else {
            return nil
        }
        loadCredentials(&model)
        return model
    }

    func saveCustomConfig(customConfig: CustomConfigModel) {
        // Save credentials to Keychain; persist a credential-stripped Realm row.
        saveCredentials(customConfig)
        var realmModel = customConfig
        realmModel.username = ""
        realmModel.password = ""
        localDatabase.saveCustomConfig(customConfig: realmModel)
    }
}

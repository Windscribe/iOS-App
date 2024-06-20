//
//  CustomConfigRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-26.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
class CustomConfigRepositoryImpl: CustomConfigRepository {
    private let fileDatabase: FileDatabase
    private let localDatabase: LocalDatabase
    private let latencyRepo: LatencyRepository
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    init(fileDatabase: FileDatabase, localDatabase: LocalDatabase, latencyRepo: LatencyRepository, logger: FileLogger) {
        self.fileDatabase = fileDatabase
        self.localDatabase = localDatabase
        self.latencyRepo = latencyRepo
        self.logger = logger
    }

    func saveWgConfig(url: URL) -> RepositoryError? {
        logger.logD(self, "Saving custom WireGuard config file.")
        do {
            var data = try Data(contentsOf: url)
            if let fileName = url.lastPathComponent.split(separator: ".").first {
                let serverName = String(fileName)
                let fileId = UUID().uuidString
                let path = "\(fileId).conf"
                guard let stringData = String(data: data, encoding: String.Encoding.utf8) else { return RepositoryError.invalidConfigData }

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
                    return RepositoryError.invalidConfigData
                }
                guard let configData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else { return RepositoryError.invalidConfigData  }
                data = configData
                let customConfig = CustomConfig(id: fileId,
                                                name: serverName,
                                                serverAddress: serverAddress,
                                                protocolType: TextsAsset.wireGuard, port: port)
                localDatabase.saveCustomConfig(customConfig: customConfig).disposed(by: disposeBag)
                fileDatabase.saveFile(data: data, path: path)
                return nil
            }
        } catch let error {
            logger.logE(self, "Error when saving custom config file. \(error.localizedDescription)")
        }
        return RepositoryError.invalidConfigData
    }

    func saveOpenVPNConfig(url: URL) -> RepositoryError? {
        logger.logD(self, "Saving custom OpenVPN config file.")
        do {
            var data = try Data(contentsOf: url)
            if let fileName = url.lastPathComponent.split(separator: ".").first {
                let serverName = String(fileName)
                let fileId = UUID().uuidString
                let path = "\(fileId).ovpn"
                guard let stringData = String(data: data, encoding: String.Encoding.utf8) else { return RepositoryError.invalidConfigData }

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
                        return RepositoryError.invalidConfigData
                    }
                    if line.contains("route") {
                        routeLines.append(index)
                    }
                }
                for rLine in routeLines {
                    lines.remove(at: rLine)
                }
                if serverAddress == "" {
                    return RepositoryError.invalidConfigData
                }
                if protocolType == "" {
                    protocolType = TextsAsset.General.protocols[1]
                    lines.insert("proto \(protocolType.lowercased())", at: remoteLineNumber)
                }
                if port == "" {
                    guard let portsArray = localDatabase.getPorts(protocolType: protocolType) else { return RepositoryError.invalidConfigData }
                    port = portsArray[0]
                }

                if let configurationFileURL = Bundle.main.url(forResource: "cert", withExtension: "file"),
                   let configurationFileContent = try? Data(contentsOf: configurationFileURL),
                   !containsCert {
                    data.append(configurationFileContent)
                }

                guard let configData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else { return RepositoryError.invalidConfigData }
                data = configData

                let customConfig = CustomConfig(id: fileId, name: serverName, serverAddress: serverAddress, protocolType: protocolType, port: port, authRequired: authRequired)
                localDatabase.saveCustomConfig(customConfig: customConfig).disposed(by: disposeBag)
                fileDatabase.saveFile(data: data, path: path)
                return nil
            }
        } catch let error {
            logger.logE(self, "Error when saving custom OpenVPN config file. \(error.localizedDescription)")
        }
        return RepositoryError.invalidConfigData
    }

    func removeOpenVPNConfig(fileId: String) {
        logger.logD(self, "Removing custom OpenVPN config file.")
        fileDatabase.removeFile(path: "\(fileId).ovpn")
        localDatabase.removeCustomConfig(fileId: fileId)
    }

    func removeWgConfig(fileId: String) {
        logger.logD(self, "Removing custom config file.")
        fileDatabase.removeFile(path: "\(fileId).conf")
        localDatabase.removeCustomConfig(fileId: fileId)
    }
}

//
//  WireguardConfigRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol WireguardConfigRepository {
    func getCredentials() async throws
}

class WireguardConfigRepositoryImpl: WireguardConfigRepository {
    private let apiCallManager: WireguardAPIManager
    private let logger: FileLogger
    private let fileDatabase: FileDatabase
    private let wgCrendentials: WgCredentials
    private let alertManager: AlertManagerV2?

    init(apiCallManager: WireguardAPIManager, fileDatabase: FileDatabase, wgCrendentials: WgCredentials, alertManager: AlertManagerV2?, logger: FileLogger) {
        self.apiCallManager = apiCallManager
        self.fileDatabase = fileDatabase
        self.wgCrendentials = wgCrendentials
        self.alertManager = alertManager
        self.logger = logger
    }

    func getCredentials() async throws {
        try await wgInit()
        try await wgConnect()
        try retrieveTemplateWgConfig()
    }
    
    private func retrieveTemplateWgConfig() throws {
        guard let wgConfig = wgCrendentials.asWgCredentialsString(),
              let data = wgConfig.data(using: .utf8) else {
            throw RepositoryError.failedToTemplateWgConfig
        }
        fileDatabase.saveFile(data: data, path: FilePaths.wireGuard)
    }

    private func wgInit() async throws {
        guard !self.wgCrendentials.initialized() else { return }

        let userPublicKey = await self.wgCrendentials.getPublicKey() ?? ""

        do {
            let config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: false)
            self.wgCrendentials.saveInitResponse(config: config)
        } catch let error as Errors where error == .wgLimitExceeded {
            guard let alertManager = self.alertManager  else {
                let config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: true)
                self.wgCrendentials.saveInitResponse(config: config)
                return
            }
            let accept = try await alertManager.askUser(message: error.description).asPromise()
            guard accept else { throw Errors.handled }

            let config = try await self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: true)
            self.wgCrendentials.saveInitResponse(config: config)
        }
    }

    private func wgConnect() async throws {
        do {
            let deviceID = await UIDevice.current.identifierForVendor?.uuidString ?? ""
            let publicKey = await self.wgCrendentials.getPublicKey() ?? ""
            let hostName = self.wgCrendentials.serverHostName ?? ""

            let config = try await self.apiCallManager.wgConfigConnect(clientPublicKey: publicKey, hostname: hostName, deviceId: deviceID)
            self.wgCrendentials.saveConnectResponse(config: config)

        } catch let Errors.apiError(code) where code.errorCode == invalidPublicKey {
            self.wgCrendentials.delete()
            try await self.wgInit()
            let retryKey = await self.wgCrendentials.getPublicKey() ?? ""
            let config = try await self.apiCallManager.wgConfigConnect(clientPublicKey: retryKey, hostname: self.wgCrendentials.serverHostName ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
            self.wgCrendentials.saveConnectResponse(config: config)
        } catch let Errors.apiError(code) where code.errorCode == unableToSelectWgIp {
            let retryKey = await self.wgCrendentials.getPublicKey() ?? ""
            let config = try await self.apiCallManager.wgConfigConnect(clientPublicKey: retryKey, hostname: self.wgCrendentials.serverHostName ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
            self.wgCrendentials.saveConnectResponse(config: config)
        }
    }
}

//
//  CredentialsRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

actor CredentialsRepositoryImpl: @preconcurrency CredentialsRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let fileDatabase: FileDatabase
    private let vpnStateRepository: VPNStateRepository
    private let wifiManager: WifiManager
    private let logger: FileLogger
    private let preferences: Preferences
    private let userSessionRepository: UserSessionRepository
    private var cancellables = Set<AnyCancellable>()
    private var connectionMode: String?
    private var selectedProtocol: String?

    private var _openVPNCrendentials: ServerCredentialsModel?
    private var _ikev2Crendentials: ServerCredentialsModel?

    var openVPNCrendentials: ServerCredentialsModel?
    var ikev2Crendentials: ServerCredentialsModel?

    // Prevents concurrent updateServerConfig calls
    private var updateTask: Task<Void, Never>?

    init(apiManager: APIManager,
         localDatabase: LocalDatabase,
         fileDatabase: FileDatabase,
         vpnStateRepository: VPNStateRepository,
         wifiManager: WifiManager,
         preferences: Preferences,
         userSessionRepository: UserSessionRepository,
         logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.fileDatabase = fileDatabase
        self.vpnStateRepository = vpnStateRepository
        self.wifiManager = wifiManager
        self.logger = logger
        self.preferences = preferences
        self.userSessionRepository = userSessionRepository

        // Schedule loadData to run on the actor's executor
        Task {
            await self.loadData()
        }
    }

    private func loadData() {
        preferences.getConnectionMode()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                Task {
                    await self.updateConnectionMode(data)
                }
            }
            .store(in: &cancellables)

        preferences.getSelectedProtocol()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                Task {
                    await self.updateSelectedProtocol(data)
                }
            }
            .store(in: &cancellables)

        openVPNCrendentials = preferences.getOpenVPNCredentials()
        ikev2Crendentials = preferences.getIKEv2Credentials()
    }

    private func updateConnectionMode(_ mode: String?) {
        connectionMode = mode
    }

    private func updateSelectedProtocol(_ protocol: String?) {
        selectedProtocol = `protocol`
    }

    func getUpdatedOpenVPNCrendentials() async throws {
        do {
            let credentials = try await self.apiManager.getOpenVPNServerCredentials()
            let model = credentials.getModel()
            preferences.saveOpenVPNCredentials(model)
            openVPNCrendentials = model
        } catch {
            guard let cached = preferences.getOpenVPNCredentials() else {
                throw error
            }
            openVPNCrendentials = cached
        }
    }

    func getUpdatedIKEv2Crendentials() async throws {
        do {
            let credentials = try await self.apiManager.getIKEv2ServerCredentials()
            let model = credentials.getModel()
            preferences.saveIKEv2Credentials(model)
            ikev2Crendentials = model
        } catch {
            guard let cached = preferences.getIKEv2Credentials() else {
                throw error
            }
            ikev2Crendentials = cached
        }
    }

    func getUpdatedServerConfig() async throws {
        do {
            let config = try await self.apiManager.getOpenVPNServerConfig(openVPNVersion: APIParameterValues.openVPNVersion)
            if let data = Data(base64Encoded: config) {
                do {
                    try? await self.fileDatabase.removeFile(path: FilePaths.openVPN)
                    try await self.fileDatabase.saveFile(data: data, path: FilePaths.openVPN)
                } catch {
                    self.logger.logE("CredentialsRepositoryImpl", "Failed to save server config file: \(error.localizedDescription)")
                }
            }
        } catch {
            let fileContent = try await self.fileDatabase.readFile(path: FilePaths.openVPN)
            guard String(data: fileContent, encoding: .utf8) != nil else {
                throw error
            }
        }
    }

    func selectedServerCredentialsType() -> ServerCredentials.Type {
        guard let result = wifiManager.getConnectedNetwork() else {
            return OpenVPNServerCredentials.self
        }
        if result.preferredProtocolStatus == true && !vpnStateRepository.isFromProtocolFailover && !vpnStateRepository.isFromProtocolChange {
            if result.preferredProtocol == VPNProtocolType.iKEv2.identifier {
                return IKEv2ServerCredentials.self
            }
            return OpenVPNServerCredentials.self
        } else {
            if let connection = connectionMode, let selectedprotocol = selectedProtocol {
                if connection == Fields.Values.manual {
                    if selectedprotocol == VPNProtocolType.iKEv2.identifier {
                        return IKEv2ServerCredentials.self
                    }
                    return OpenVPNServerCredentials.self
                } else {
                    if result.protocolType == VPNProtocolType.iKEv2.identifier {
                        return IKEv2ServerCredentials.self
                    }
                    return OpenVPNServerCredentials.self
                }
            }
        }
        return OpenVPNServerCredentials.self
    }

    func updateServerConfig() {
        guard userSessionRepository.sessionAuth != nil else { return }

        // Cancel any existing update task and start a new one
        updateTask?.cancel()
        let task = Task {
            // Wait a moment to allow task cancellation to propagate
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            guard !Task.isCancelled else { return }

            do {
                try await getUpdatedOpenVPNCrendentials()
                guard !Task.isCancelled else { return }
                try await getUpdatedIKEv2Crendentials()
                guard !Task.isCancelled else { return }
                try await getUpdatedServerConfig()
                guard !Task.isCancelled else { return }
                self.logger.logI("CredentialsRepositoryImpl", "Server config and credentials updated.")
            } catch {
                if !Task.isCancelled {
                    self.logger.logE("CredentialsRepositoryImpl", "Failed to update server config and credentials.")
                }
            }
        }
        updateTask = task
    }
}

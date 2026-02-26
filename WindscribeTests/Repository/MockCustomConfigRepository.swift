//
//  MockCustomConfigRepository.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 13/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

final class MockCustomConfigRepository: CustomConfigRepository {
    // CustomConfigRepository protocol properties
    var customConfigs = CurrentValueSubject<[CustomConfigModel], Never>([])

    // Mock storage
    private var configStorage: [String: CustomConfigModel] = [:]

    // Test configuration flags
    var shouldThrowOnSaveWgConfig = false
    var shouldThrowOnSaveOpenVPNConfig = false
    var shouldThrowOnSaveOpenVPNCustomConfig = false
    var customSaveWgConfigError: Error?
    var customSaveOpenVPNConfigError: Error?
    var customSaveOpenVPNCustomConfigError: Error?

    // Call tracking
    var saveWgConfigCallCount = 0
    var removeWgConfigCallCount = 0
    var saveOpenVPNConfigCallCount = 0
    var removeOpenVPNConfigCallCount = 0
    var removeCustomConfigCallCount = 0
    var saveOpenVPNCustomConfigCallCount = 0
    var getCustomConfigCallCount = 0
    var saveCustomConfigCallCount = 0

    var lastSavedWgConfigURL: URL?
    var lastRemovedWgConfigFileId: String?
    var lastSavedOpenVPNConfigURL: URL?
    var lastRemovedOpenVPNConfigFileId: String?
    var lastRemovedCustomConfigFileId: String?
    var lastSavedCustomConfig: CustomConfigModel?
    var lastGetCustomConfigFileId: String?
    var lastSavedOpenVPNCustomConfigData: Data?
    var lastSavedOpenVPNCustomConfigInfo: OpenVPNConnectionInfo?
    var lastSavedOpenVPNCustomConfigName: String?

    // CustomConfigRepository protocol methods
    func saveWgConfig(url: URL) async throws {
        saveWgConfigCallCount += 1
        lastSavedWgConfigURL = url

        if shouldThrowOnSaveWgConfig {
            throw customSaveWgConfigError ?? NSError(domain: "MockCustomConfigRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock save WG config error"])
        }
    }

    func removeWgConfig(fileId: String) async {
        removeWgConfigCallCount += 1
        lastRemovedWgConfigFileId = fileId
        configStorage.removeValue(forKey: fileId)
        updateCustomConfigs()
    }

    func saveOpenVPNConfig(url: URL) async throws {
        saveOpenVPNConfigCallCount += 1
        lastSavedOpenVPNConfigURL = url

        if shouldThrowOnSaveOpenVPNConfig {
            throw customSaveOpenVPNConfigError ?? NSError(domain: "MockCustomConfigRepository", code: -2, userInfo: [NSLocalizedDescriptionKey: "Mock save OpenVPN config error"])
        }
    }

    func removeOpenVPNConfig(fileId: String) async {
        removeOpenVPNConfigCallCount += 1
        lastRemovedOpenVPNConfigFileId = fileId
        configStorage.removeValue(forKey: fileId)
        updateCustomConfigs()
    }

    func removeCustomConfig(fileId: String) {
        removeCustomConfigCallCount += 1
        lastRemovedCustomConfigFileId = fileId
        configStorage.removeValue(forKey: fileId)
        updateCustomConfigs()
    }

    func saveOpenVPNCustomConfig(data: Data, configInfo: OpenVPNConnectionInfo, configuationName: String) async throws -> CustomConfigModel {
        saveOpenVPNCustomConfigCallCount += 1
        lastSavedOpenVPNCustomConfigData = data
        lastSavedOpenVPNCustomConfigInfo = configInfo
        lastSavedOpenVPNCustomConfigName = configuationName

        if shouldThrowOnSaveOpenVPNCustomConfig {
            throw customSaveOpenVPNCustomConfigError ?? NSError(domain: "MockCustomConfigRepository", code: -3, userInfo: [NSLocalizedDescriptionKey: "Mock save OpenVPN custom config error"])
        }

        // Create a mock CustomConfigModel using test helper extension
        let customConfig = CustomConfigModel(
            id: UUID().uuidString,
            name: configuationName,
            serverAddress: "mock.server.com",
            protocolType: "OpenVPN",
            port: configInfo.port,
            username: "",
            password: "",
            authRequired: false,
            saveCredentials: true
        )

        configStorage[customConfig.id] = customConfig
        updateCustomConfigs()

        return customConfig
    }

    func getCustomConfig(fileId: String) -> CustomConfigModel? {
        getCustomConfigCallCount += 1
        lastGetCustomConfigFileId = fileId
        return configStorage[fileId]
    }

    func saveCustomConfig(customConfig: CustomConfigModel) {
        saveCustomConfigCallCount += 1
        lastSavedCustomConfig = customConfig
        configStorage[customConfig.id] = customConfig
        updateCustomConfigs()
    }

    // MARK: - Helper Methods

    private func updateCustomConfigs() {
        let configs = Array(configStorage.values)
        customConfigs.send(configs)
    }

    func reset() {
        configStorage.removeAll()
        customConfigs.send([])

        shouldThrowOnSaveWgConfig = false
        shouldThrowOnSaveOpenVPNConfig = false
        shouldThrowOnSaveOpenVPNCustomConfig = false
        customSaveWgConfigError = nil
        customSaveOpenVPNConfigError = nil
        customSaveOpenVPNCustomConfigError = nil

        saveWgConfigCallCount = 0
        removeWgConfigCallCount = 0
        saveOpenVPNConfigCallCount = 0
        removeOpenVPNConfigCallCount = 0
        removeCustomConfigCallCount = 0
        saveOpenVPNCustomConfigCallCount = 0
        getCustomConfigCallCount = 0
        saveCustomConfigCallCount = 0

        lastSavedWgConfigURL = nil
        lastRemovedWgConfigFileId = nil
        lastSavedOpenVPNConfigURL = nil
        lastRemovedOpenVPNConfigFileId = nil
        lastRemovedCustomConfigFileId = nil
        lastSavedCustomConfig = nil
        lastGetCustomConfigFileId = nil
        lastSavedOpenVPNCustomConfigData = nil
        lastSavedOpenVPNCustomConfigInfo = nil
        lastSavedOpenVPNCustomConfigName = nil
    }

    func addConfig(_ config: CustomConfigModel) {
        configStorage[config.id] = config
        updateCustomConfigs()
    }

    func getConfigCount() -> Int {
        return configStorage.count
    }

    func getAllConfigs() -> [CustomConfigModel] {
        return Array(configStorage.values)
    }
}

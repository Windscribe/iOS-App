//
//  StaticIpRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class StaticIpRepositoryImpl: StaticIpRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    /// Fetches static IPs and updates the local database.
    func getStaticServers() async throws -> [StaticIP] {
        do {
            let result = try await apiManager.getStaticIpList()
            localDatabase.deleteStaticIps(ignore: Array(result.staticIPs).map { $0.staticIP })
            localDatabase.saveStaticIPs(staticIps: Array(result.staticIPs))
            return Array(result.staticIPs)
        } catch {
            logger.logE("StaticIpRepository", "Error getting static IPs: \(error)")

            // Fallback to cached data if available and not empty
            if let cachedIps = localDatabase.getStaticIPs(), !cachedIps.isEmpty {
                return cachedIps
            } else {
                throw error
            }
        }
    }

    func getStaticIp(id: Int) -> StaticIP? {
        return localDatabase.getStaticIPs()?.first { $0.id == id }
    }
}

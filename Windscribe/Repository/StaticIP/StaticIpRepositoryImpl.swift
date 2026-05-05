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

    var staticIPs = [StaticIPModel]()

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger

        staticIPs = (localDatabase.getStaticIPs() ?? [])
            .sorted { $0.cityName.lowercased() < $1.cityName.lowercased() }
    }

    /// Fetches static IPs and updates the local database.
    func updateStaticServers() async throws {
        do {
            let result = try await apiManager.getStaticIpList()
            localDatabase.deleteStaticIps(ignore: Array(result.staticIPs).map { $0.staticIP })
            localDatabase.saveStaticIPs(staticIps: result.staticIPs.map { $0.getModel() })
            staticIPs = result.staticIPs.map { $0.getModel() }
                .sorted { $0.cityName.lowercased() < $1.cityName.lowercased() }
        } catch {
            logger.logE("StaticIpRepository", "Error getting static IPs: \(error)")

            // Fallback to cached data if available and not empty
            if let cachedIps = localDatabase.getStaticIPs(), !cachedIps.isEmpty {
                staticIPs = cachedIps
                    .sorted { $0.cityName.lowercased() < $1.cityName.lowercased() }
            } else {
                throw error
            }
        }
    }

    func getStaticIp(id: Int) -> StaticIPModel? {
        return localDatabase.getStaticIPs()?.first { $0.id == id }
    }
}

//
//  ServerRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

class ServerRepositoryImpl: ServerRepository {
    var updatedServerModelsSubject = CurrentValueSubject<[ServerModel], Never>([])

    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let userSessionRepository: UserSessionRepository
    private let advanceRepository: AdvanceRepository
    private let preferences: Preferences
    private let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()

    init(apiManager: APIManager, localDatabase: LocalDatabase, userSessionRepository: UserSessionRepository, preferences: Preferences, advanceRepository: AdvanceRepository, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.userSessionRepository = userSessionRepository
        self.advanceRepository = advanceRepository
        self.preferences = preferences
        self.logger = logger

        Task {
            await loadInitialServers()
        }
    }

    var currentServerModels: [ServerModel] {
        updatedServerModelsSubject.value
    }

    @MainActor
    private func loadInitialServers() async {
        if let servers = self.localDatabase.getServers() {
            self.updateServerModels(servers: servers)
        }
    }

    func getUpdatedServers() async throws -> [Server] {
        guard let user = userSessionRepository.user else {
            throw Errors.validationFailure
        }
        let countryCode = advanceRepository.getCountryOverride() ?? ""

        do {
            let serverList = try await self.apiManager.getServerList(languageCode: countryCode, revision: user.locationHash, isPro: user.allAccessPlan, alcList: user.alcList)

            return await MainActor.run {
                let servers = Array(serverList.servers)
                for s in servers {
                    for g in s.groups {
                        g.setBestNode(advanceRepository: self.advanceRepository)
                    }
                }
                self.localDatabase.saveServers(servers: servers)
                self.updateServerModels(servers: servers)
                return servers
            }
        } catch {
            let servers = await MainActor.run {
                self.localDatabase.getServers()
            }

            if let servers = servers {
                await MainActor.run {
                    self.updateServerModels(servers: servers)
                }
                return servers
            } else {
                throw error
            }
        }
    }

    func updateRegions(with regions: [ExportedRegion]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.preferences.saveCustomLocationsNames(value: regions)
            guard let servers = self.localDatabase.getServers() else { return }
            self.updateServerModels(servers: servers)
        }
    }

    @MainActor
    private func updateServerModels(servers: [Server]) {
        logger.logI("ServerRepositoryImpl", "Stating merge of local and external servers")
        let regions = preferences.getCustomLocationsNames()
        if regions.isEmpty {
            updatedServerModelsSubject.send(servers.compactMap { $0.getServerModel() })
            return
        }

        var mergedModels: [ServerModel] = []
        servers.forEach { server in
            if let region = regions.first(where: { $0.id == server.id }) {
                var mergedGroups = [GroupModel]()
                server.groups.forEach { group in
                    if let city = region.cities.first(where: { $0.id == group.id }) {
                        mergedGroups.append(group.getGroupModel(customCity: city.name,
                                                                customNick: city.nickname,
                                                                countryCode: server.countryCode))
                    } else {
                        mergedGroups.append(group.getGroupModel(countryCode: server.countryCode))
                    }
                }
                if server.groups.count == mergedGroups.count {
                    mergedModels.append(server.getServerModel(customName: region.country,
                                                              groupModels: mergedGroups))
                } else {
                    mergedModels.append(server.getServerModel(customName: region.country,
                                                              groupModels: server.getServerModel().groups))
                }
            } else {
                mergedModels.append(server.getServerModel())
            }
        }
        if mergedModels.count == servers.count {
            logger.logI("ServerRepositoryImpl", "Merge of local and external servers successful")
            updatedServerModelsSubject.send(mergedModels)
            return
        }
    }
}

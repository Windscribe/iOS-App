//
//  ServerRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class ServerRepositoryImpl: ServerRepository {
    var updatedServerModelsSubject = BehaviorSubject<[ServerModel]>(value: [])

    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let userRepository: UserRepository
    private let advanceRepository: AdvanceRepository
    private let preferences: Preferences
    private let logger: FileLogger
    private let disposeBag = DisposeBag()

    init(apiManager: APIManager, localDatabase: LocalDatabase, userRepository: UserRepository, preferences: Preferences, advanceRepository: AdvanceRepository, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.userRepository = userRepository
        self.advanceRepository = advanceRepository
        self.preferences = preferences
        self.logger = logger

        loadInitialServers()
    }

    var currentServerModels: [ServerModel] {
        (try? updatedServerModelsSubject.value()) ?? []
    }

    private func loadInitialServers() {
        if let servers = self.localDatabase.getServers() {
            self.updateServerModels(servers: servers)
        }
    }

    func getUpdatedServers() -> Single<[Server]> {
        guard let user = try? userRepository.user.value() else {
            return Single.error(Errors.validationFailure)
        }
        let countryCode = advanceRepository.getCountryOverride() ?? ""
        return apiManager.getServerList(languageCode: countryCode, revision: user.locationHash, isPro: user.allAccessPlan, alcList: user.alcList)
            .observe(on: MainScheduler.instance)
            .map { serverList in
                let servers = Array(serverList.servers)
                for s in servers {
                    for g in s.groups {
                        g.setBestNode(advanceRepository: self.advanceRepository)
                    }
                }
                self.localDatabase.saveServers(servers: servers)
                self.updateServerModels(servers: servers)
                return servers
            }.catch { error in
                if let servers = self.localDatabase.getServers() {
                    self.updateServerModels(servers: servers)
                    return Single.just(servers)
                } else {
                    return Single.error(error)
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

    private func updateServerModels(servers: [Server]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logger.logI("ServerRepositoryImpl", "Stating merge of local and external servers")
            let regions = preferences.getCustomLocationsNames()
            if regions.isEmpty {
                updatedServerModelsSubject.onNext(servers.compactMap { $0.getServerModel() })
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
                                                                    countryCode: region.country))
                        } else {
                            mergedGroups.append(group.getGroupModel(countryCode: region.country))
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
                updatedServerModelsSubject.onNext(mergedModels)
                return
            }
        }
    }
}

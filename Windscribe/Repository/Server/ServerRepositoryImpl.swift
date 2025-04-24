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
    private var unusedFavourites: [String] = []

    init(apiManager: APIManager, localDatabase: LocalDatabase, userRepository: UserRepository, preferences: Preferences, advanceRepository: AdvanceRepository, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.userRepository = userRepository
        self.advanceRepository = advanceRepository
        self.preferences = preferences
        self.logger = logger
    }

    var currentServerModels: [ServerModel] {
        (try? updatedServerModelsSubject.value()) ?? []
    }

    func getUpdatedServers() -> Single<[Server]> {
        guard let user = try? userRepository.user.value() else {
            return Single.error(Errors.validationFailure)
        }
        let countryCode = advanceRepository.getCountryOverride() ?? ""
        return apiManager.getServerList(languageCode: countryCode, revision: user.locationHash, isPro: user.allAccessPlan, alcList: user.alcList)
            .map { serverList in
                let servers = Array(serverList.servers)
                for s in servers {
                    for g in s.groups {
                        g.setBestNode(advanceRepository: self.advanceRepository)
                    }
                }
                self.localDatabase.saveServers(servers: servers)
                self.rebuildFavouriteList(serverList: servers)
                self.updateServerModels()
                return servers
            }.catch { error in
                if let ips = self.localDatabase.getServers() {
                    return Single.just(ips)
                } else {
                    return Single.error(error)
                }
            }
    }

    func updateRegions(with regions: [ExportedRegion]) {
        preferences.saveCustomLocationsNames(value: regions)
        updateServerModels()
    }

    private func updateServerModels() {
        guard let servers = localDatabase.getServers() else { return }
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
                                                                customNick: city.nickname))
                    }
                }
                if server.groups.count == mergedGroups.count {
                    mergedModels.append(server.getServerModel(customName: region.country,
                                                              groupModels: mergedGroups))
                }
            }
        }
        if mergedModels.count == servers.count {
            logger.logI("ServerRepositoryImpl", "Merge of local and external servers successful")
            updatedServerModelsSubject.onNext(mergedModels)
            return
        }
    }

    private func rebuildFavouriteList(serverList: [Server]) {
        unusedFavourites.removeAll()
        DispatchQueue.main.async {
            for favourite in self.localDatabase.getFavNodeSync() {
                for server in serverList {
                    for group in server.groups where String(group.id) == favourite.groupId {
                        if let lastSelectedNode = self.getLastSelectedNode(
                            group: group,
                            server: server,
                            favourite: favourite) {
                            let favNode = FavNode(node: lastSelectedNode,
                                                  group: group,
                                                  server: server)
                            self.localDatabase.saveFavNode(favNode: favNode).disposed(by: self.disposeBag)
                        }
                    }
                }
            }
            for hostname in self.unusedFavourites {
                self.localDatabase.removeFavNode(hostName: hostname)
            }
        }
    }

    private func getLastSelectedNode(group: Group, server _: Server, favourite: FavNode) -> Node? {
        var node = group.nodes.filter { $0.hostname == favourite.hostname }.first
        if node == nil && group.nodes.count > 0 {
            unusedFavourites.append(favourite.hostname)
            node = group.nodes.randomElement()
        }
        return node
    }
}

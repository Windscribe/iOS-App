//
//  ServerRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class ServerRepositoryImpl: ServerRepository {
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

    func getUpdatedServers() -> Single<[Server]> {
        guard let user = try? userRepository.user.value() else {
            return Single.error(Errors.validationFailure)
        }
        let countryCode = advanceRepository.getCountryOverride() ?? ""
        return apiManager.getServerList(languageCode: countryCode, revision: user.locationHash, isPro: user.allAccessPlan, alcList: user.alcList)
            .map { serverList in
                let servers = serverList.servers.toArray()
                for s in servers {
                    for g in s.groups {
                        g.setBestNode(advanceRepository: self.advanceRepository)
                    }
                }
                self.localDatabase.saveServers(servers: servers)
                self.rebuildFavouriteList(serverList: servers)
                return servers
            }.catch { error in
                if let ips = self.localDatabase.getServers() {
                    return Single.just(ips)
                } else {
                    return Single.error(error)
                }
            }
    }

    private func rebuildFavouriteList(serverList: [Server]) {
        unusedFavourites.removeAll()
        DispatchQueue.main.async {
            for favourite in self.localDatabase.getFavNodeSync() {
                for server in serverList {
                    for group in server.groups {
                        if String(group.id) == favourite.groupId {
                            if let lastSelectedNode = self.getLastSelectedNode(group: group, server: server, favourite: favourite) {
                                let favNode = FavNode(node: lastSelectedNode,
                                                      group: group,
                                                      server: server)
                                self.localDatabase.saveFavNode(favNode: favNode).disposed(by: self.disposeBag)
                            }
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

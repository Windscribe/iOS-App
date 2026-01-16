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
import RxSwift

protocol ServerRepository {
    var serverListSubject: CurrentValueSubject<[ServerModel], Never> { get }
    var currentServerModels: [ServerModel] { get }
    var currentGroupModels: [GroupModel] { get }
    var favouriteListSubject: CurrentValueSubject<[FavouriteModel], Never> { get }

    func updatedServers() async throws
    func updateRegions(with regions: [ExportedRegion])

    func getFavorite(from locationId: String) -> FavouriteModel?
    func getLocationPinned(for groupId: Int) -> String?

    func removeFavorite(with groupId: String)
    func removeFavorite(with groupId: Int)
    func saveFavorite(for favourite: FavouriteModel)
}

class ServerRepositoryImpl: ServerRepository {
    var serverListSubject = CurrentValueSubject<[ServerModel], Never>([])
    var favouriteListSubject = CurrentValueSubject<[FavouriteModel], Never>([])

    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let userSessionRepository: UserSessionRepository
    private let advanceRepository: AdvanceRepository
    private let preferences: Preferences
    private let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    init(apiManager: APIManager, localDatabase: LocalDatabase, userSessionRepository: UserSessionRepository, preferences: Preferences, advanceRepository: AdvanceRepository, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.userSessionRepository = userSessionRepository
        self.advanceRepository = advanceRepository
        self.preferences = preferences
        self.logger = logger

        loadInitialServers()

        localDatabase.getFavouriteListObservable()
            .toPublisher(initialValue: [])
            .replaceError(with: [])
            .sink { [weak self] favouriteList in
                self?.favouriteListSubject.send(
                    favouriteList
                        .filter { !$0.isInvalidated }
                        .map { $0.getModel() }
                )
            }
            .store(in: &cancellables)
    }

    var currentServerModels: [ServerModel] {
        serverListSubject.value
    }

    var currentGroupModels: [GroupModel] {
        currentServerModels.flatMap { $0.groups }
    }

    private func loadInitialServers() {
        if let servers = self.localDatabase.getServers() {
            self.updateServerModels(mapServersToModel(servers))
        }
    }

    func updatedServers() async throws {
        guard let session = userSessionRepository.sessionModel else {
            throw Errors.validationFailure
        }
        let countryCode = advanceRepository.getCountryOverride() ?? ""

        do {
            let serverList = try await self.apiManager.getServerList(languageCode: countryCode, revision: session.locHash, isPro: session.isPremium, alcList: session.alc)

            let servers = Array(serverList.servers)
            for server in servers {
                for group in server.groups {
                    group.setBestNode(advanceRepository: self.advanceRepository)
                }
            }

            self.updateServerModels(mapServersToModel(servers))
            self.localDatabase.saveServers(servers: servers)
        } catch {
            if let servers = self.localDatabase.getServers() {
                self.updateServerModels(mapServersToModel(servers))
                return
            } else {
                throw error
            }
        }
    }

    func updateRegions(with regions: [ExportedRegion]) {
        self.preferences.saveCustomLocationsNames(value: regions)
        guard let servers = self.localDatabase.getServers() else { return }
        self.updateServerModels(mapServersToModel(servers))
    }

    private func mapServersToModel(_ servers: [Server]) -> [ServerModel] {
        servers.map { $0.getServerModel() }
    }

    private func updateServerModels(_ serverList: [ServerModel]) {
        logger.logI("ServerRepositoryImpl", "Stating merge of local and external servers")
        let regions = preferences.getCustomLocationsNames()
        if regions.isEmpty {
            serverListSubject.send(serverList)
            return
        }

        var mergedModels: [ServerModel] = []
        serverList.forEach { server in
            if let region = regions.first(where: { $0.id == server.id }) {
                var mergedGroups = [GroupModel]()
                server.groups.forEach { group in
                    if let city = region.cities.first(where: { $0.id == group.id }) {
                        mergedGroups.append(group.getCustomGroupModel(customCity: city.name,
                                                                customNick: city.nickname,
                                                                countryCode: server.countryCode))
                    } else {
                        mergedGroups.append(group.getCustomGroupModel(countryCode: server.countryCode))
                    }
                }
                if server.groups.count == mergedGroups.count {
                    mergedModels.append(server.getCustomServerModel(customName: region.country,
                                                              groupModels: mergedGroups))
                } else {
                    mergedModels.append(server.getCustomServerModel(customName: region.country,
                                                              groupModels: server.groups))
                }
            } else {
                mergedModels.append(server)
            }
        }
        if mergedModels.count == serverList.count {
            logger.logI("ServerRepositoryImpl", "Merge of local and external servers successful")
            serverListSubject.send(mergedModels)
            return
        }
    }

    func getFavorite(from locationId: String) -> FavouriteModel? {
        localDatabase.getFavouriteList()
            .first { $0.id == locationId }?
            .getModel()
    }

    func getLocationPinned(for groupId: Int) -> String? {
        localDatabase.getFavouriteList().first {
            $0.id == String(groupId) && $0.pinnedNodeIp != nil
        }?.pinnedNodeIp
    }

    func removeFavorite(with groupId: String) {
        localDatabase.removeFavourite(groupId: groupId)
    }

    func removeFavorite(with groupId: Int) {
        removeFavorite(with: "\(groupId)")
    }

    func saveFavorite(for favourite: FavouriteModel) {
        localDatabase.saveFavourite(favourite: favourite.getObject())
            .disposed(by: disposeBag)
    }
}

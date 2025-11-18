//
//  ServerListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ServerListViewModelType {
    var presentConnectingAlertTrigger: PublishSubject<Void> { get }
    var showMaintenanceLocationTrigger: PublishSubject<Void> { get }
    var showUpgradeTrigger: PublishSubject<Void> { get }
    var reloadTrigger: PublishSubject<Void> { get }

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    func connectToBestLocation()
}

class ServerListViewModel: ServerListViewModelType {
    var presentConnectingAlertTrigger = PublishSubject<Void>()
    var showMaintenanceLocationTrigger = PublishSubject<Void>()
    var showUpgradeTrigger = PublishSubject<Void>()
    var reloadTrigger = PublishSubject<Void>()

    private let logger: FileLogger
    private let vpnStateRepository: VPNStateRepository
    private let connectivity: ConnectivityManager
    private let localDataBase: LocalDatabase
    private let sessionRepository: SessionRepository
    private let locationsManager: LocationsManager
    private let protocolManager: ProtocolManagerType

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         localDataBase: LocalDatabase,
         sessionRepository: SessionRepository,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnStateRepository = vpnStateRepository
        self.connectivity = connectivity
        self.localDataBase = localDataBase
        self.sessionRepository = sessionRepository
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel) {
        if !connectivity.internetConnectionAvailable() {
            return
        }

        if checkMaintenanceLocation(server: server, group: group) {
            showMaintenanceLocationTrigger.onNext(())
            return
        }

        if !sessionRepository.canAccesstoProLocation() && group.premiumOnly {
            showUpgradeTrigger.onNext(())
            return
        } else if !group.canConnect() {
            reloadTrigger.onNext(())
        } else if vpnStateRepository.configurationState == ConfigurationState.initial {
            guard let bestNode = group.bestNode else { return }
            logger.logD("ServerListViewModel", "Tapped on a node with groupID: \(group.id) \(bestNode.hostname) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(group.id)")
            Task {
                self.logger.logI("ServerListViewModel", "setSelectedServerAndGroup for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentConnectingAlertTrigger.onNext(())
        }
    }

    func connectToBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnStateRepository.isConnecting() {
            self.logger.logD("ServerListViewModel", "Tapped on Best Location with ID \(locationID) from the server list.")
            self.locationsManager.selectBestLocation(with: locationID)
            Task {
                self.logger.logI("ServerListViewModel", "connectToBestLocation for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            self.presentConnectingAlertTrigger.onNext(())
        }
    }
}

extension ServerListViewModel {
    /// true: under maintenance
    /// false: not
    private func checkMaintenanceLocation(server: ServerModel, group: GroupModel) -> Bool {
        if server.status == false {
            return true
        }
        if !group.isNodesAvailable() && !group.premiumOnly {
            return true
        } else if !group.isNodesAvailable() && group.premiumOnly && sessionRepository.isPremium == true {
            return true
        }
        return false
    }
}

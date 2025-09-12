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
    private let vpnManager: VPNManager
    private let connectivity: Connectivity
    private let localDataBase: LocalDatabase
    private let sessionManager: SessionManaging
    private let locationsManager: LocationsManager
    private let protocolManager: ProtocolManagerType

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         localDataBase: LocalDatabase,
         sessionManager: SessionManaging,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.localDataBase = localDataBase
        self.sessionManager = sessionManager
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

        if !sessionManager.canAccesstoProLocation() && group.premiumOnly {
            showUpgradeTrigger.onNext(())
            return
        } else if !group.canConnect() {
            reloadTrigger.onNext(())
        } else if vpnManager.configurationState == ConfigurationState.initial {
            guard let bestNode = group.bestNode else { return }
            logger.logD("ServerListViewModel", "Tapped on a node with groupID: \(group.id) \(bestNode.hostname) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(group.id)")
            Task {
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentConnectingAlertTrigger.onNext(())
        }
    }

    func connectToBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnManager.isConnecting() {
            self.logger.logD("ServerListViewModel", "Tapped on Best Location with ID \(locationID) from the server list.")
            self.locationsManager.selectBestLocation(with: locationID)
            Task {
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
        } else if !group.isNodesAvailable() && group.premiumOnly && sessionManager.session?.isPremium == true {
            return true
        }
        return false
    }
}

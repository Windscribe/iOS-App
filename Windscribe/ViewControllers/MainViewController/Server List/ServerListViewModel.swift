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
    private let sessionManager: SessionManagerV2
    private let locationsManager: LocationsManagerType
    private let protocolManager: ProtocolManagerType

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         localDataBase: LocalDatabase,
         sessionManager: SessionManagerV2,
         locationsManager: LocationsManagerType,
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

        if !sessionManager.canAccesstoProLocation() && group.premiumOnly ?? false {
            showUpgradeTrigger.onNext(())
            return
        } else if !group.canConnect() {
            reloadTrigger.onNext(())
        } else if !vpnManager.isConnecting() {
            guard let bestNode = group.bestNode,
                  let bestNodeHostname = bestNode.hostname,
                  let groupId = group.id else { return }
            logger.logD(self, "Tapped on a node with groupID: \(groupId) \(bestNodeHostname) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(groupId)")
            Task {
                await protocolManager.refreshProtocols(shouldReset: true, shouldUpdate: true, shouldReconnect: true)
            }
        } else {
            presentConnectingAlertTrigger.onNext(())
        }
    }

    func connectToBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnManager.isConnecting() {
            self.logger.logD(self, "Tapped on Best Location with ID \(locationID) from the server list.")
            self.locationsManager.selectBestLocation(with: locationID)
            Task {
                await protocolManager.refreshProtocols(shouldReset: true, shouldUpdate: true, shouldReconnect: true)
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
        guard let premiumOnly = group.premiumOnly else {
            return false
        }
        if !group.isNodesAvailable() && !premiumOnly {
            return true
        } else if !group.isNodesAvailable() && premiumOnly && sessionManager.session?.isPremium == true {
            return true
        }
        return false
    }
}

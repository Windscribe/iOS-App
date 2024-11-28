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
    var configureVPNTrigger: PublishSubject<Void> { get }
    var showMaintenanceLocationTrigger: PublishSubject<Void> { get }
    var showUpgradeTrigger: PublishSubject<Void> { get }
    var reloadTrigger: PublishSubject<Void> { get }

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    func connectToBestLocation()
}

class ServerListViewModel: ServerListViewModelType {
    var presentConnectingAlertTrigger = PublishSubject<Void>()
    var configureVPNTrigger = PublishSubject<Void>()
    var showMaintenanceLocationTrigger = PublishSubject<Void>()
    var showUpgradeTrigger = PublishSubject<Void>()
    var reloadTrigger = PublishSubject<Void>()

    let logger: FileLogger
    let vpnManager: VPNManager
    let connectivity: Connectivity
    let localDataBase: LocalDatabase
    let preferences: Preferences
    let sessionManager: SessionManagerV2
    let locationsManager: LocationsManagerType

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         localDataBase: LocalDatabase,
         preferences: Preferences,
         sessionManager: SessionManagerV2,
         locationsManager: LocationsManagerType) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.localDataBase = localDataBase
        self.preferences = preferences
        self.sessionManager = sessionManager
        self.locationsManager = locationsManager
    }

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel) {
        if !connectivity.internetConnectionAvailable() {
            return
        }

        if checkMaintenanceLocation(server: server, group: group) {
            showMaintenanceLocationTrigger.onNext(())
            return
        }

        if !sessionManager.canAccesstoProLocation() &&
            group.premiumOnly ?? false
        {
            showUpgradeTrigger.onNext(())
            return
        } else if !group.canConnect() {
            reloadTrigger.onNext(())
        } else if !vpnManager.isConnecting() {
            guard let bestNode = group.bestNode,
                  let bestNodeHostname = bestNode.hostname,
                  let groupId = group.id else { return }
            logger.logD(self, "Tapped on a node with groupID: \(groupId) \(bestNodeHostname) from the server list.")
            preferences.saveLastSelectedLocation(with: "\(groupId)")
            configureVPNTrigger.onNext(())
        } else {
            presentConnectingAlertTrigger.onNext(())
        }
    }

    func connectToBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnManager.isConnecting() {
            self.logger.logD(self, "Tapped on Best Location with ID \(locationID) from the server list.")
            self.locationsManager.selectBestLocation(with: locationID)
            self.configureVPNTrigger.onNext(())
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

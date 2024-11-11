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

    var logger: FileLogger
    var vpnManager: VPNManager
    var connectivity: Connectivity
    var localDataBase: LocalDatabase
    var preferences: Preferences
    var sessionManager: SessionManagerV2

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         localDataBase: LocalDatabase,
         preferences: Preferences, sessionManager: SessionManagerV2)
    {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.localDataBase = localDataBase
        self.preferences = preferences
        self.sessionManager = sessionManager
    }

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    {
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
        localDataBase.getBestLocation().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: { bestLocation in
            if let bestLocation = bestLocation, !self.vpnManager.isConnecting() {
                self.logger.logD(MainViewController.self, "Tapped on Best Location \(bestLocation.hostname) from the server list.")
                self.preferences.saveBestLocation(with: "\(bestLocation.groupId)")
                self.configureVPNTrigger.onNext(())
            } else {
                self.presentConnectingAlertTrigger.onNext(())
            }
        }).disposed(by: disposeBag)
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

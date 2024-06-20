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
    var presentConnectingAlertTrigger: PublishSubject<()> { get }
    var configureVPNTrigger: PublishSubject<()> { get }
    var showMaintenanceLocationTrigger: PublishSubject<()> { get }
    var showUpgradeTrigger: PublishSubject<()> { get }
    var reloadTrigger: PublishSubject<()> { get }

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    func connectToBestLocation()
}

class ServerListViewModel: ServerListViewModelType {
    var presentConnectingAlertTrigger = PublishSubject<()>()
    var configureVPNTrigger = PublishSubject<()>()
    var showMaintenanceLocationTrigger = PublishSubject<()>()
    var showUpgradeTrigger = PublishSubject<()>()
    var reloadTrigger = PublishSubject<()>()

    var logger: FileLogger
    var vpnManager: VPNManager
    var connectivity: Connectivity
    var localDataBase: LocalDatabase
    var sessionManager: SessionManagerV2
    var connectionStateManager: ConnectionStateManagerType

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         localDataBase: LocalDatabase,
         connectionStateManager: ConnectionStateManagerType, sessionManager: SessionManagerV2) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.localDataBase = localDataBase
        self.connectionStateManager = connectionStateManager
        self.sessionManager = sessionManager
    }

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel) {
        if !connectivity.internetConnectionAvailable() {
            return
        }

        if vpnManager.isDisconnecting() {
            connectionStateManager.checkConnectedState()
        }
        if checkMaintenanceLocation(server: server, group: group) {
            showMaintenanceLocationTrigger.onNext(())
            return
        }

        if !canAccesstoProLocation() &&
            group.premiumOnly ?? false {
            showUpgradeTrigger.onNext(())
            return
        } else if !group.canConnect() {
            reloadTrigger.onNext(())
        } else if !connectionStateManager.isConnecting() {
            guard let bestNode = group.bestNode,
                  let bestNodeHostname = bestNode.hostname,
                  let serverName = server.name,
                  let countryCode = server.countryCode,
                  let dnsHostname = server.dnsHostname,
                  let hostname = bestNode.hostname,
                  let serverAddress = bestNode.ip2,
                  let nickName = group.nick,
                  let cityName = group.city,
                  let groupId = group.id else { return }
            logger.logD(self, "Tapped on a node \(serverName) \(bestNodeHostname) from the server list.")
            vpnManager.selectedNode = SelectedNode(countryCode: countryCode,
                                                   dnsHostname: dnsHostname,
                                                   hostname: hostname,
                                                   serverAddress: serverAddress,
                                                   nickName: nickName,
                                                   cityName: cityName,
                                                   groupId: groupId)
            configureVPNTrigger.onNext(())
        } else {
            presentConnectingAlertTrigger.onNext(())
        }
    }

    func connectToBestLocation() {
        localDataBase.getBestLocation().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: { bestLocation in
            if !self.connectionStateManager.isConnecting() {
                self.logger.logD(MainViewController.self, "Tapped on Best Location \(bestLocation.hostname) from the server list.")
                self.vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode,
                                                       dnsHostname: bestLocation.dnsHostname,
                                                       hostname: bestLocation.hostname,
                                                       serverAddress: bestLocation.ipAddress,
                                                       nickName: bestLocation.nickName,
                                                       cityName: bestLocation.cityName,
                                                       groupId: bestLocation.groupId)
                self.configureVPNTrigger.onNext(())
            } else {
                self.presentConnectingAlertTrigger.onNext(())
            }
        }).disposed(by: disposeBag)
    }
}

extension ServerListViewModel {
    private func canAccesstoProLocation() -> Bool {
        guard let session = sessionManager.session else { return false }
        return session.isPremium
    }

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
        } else if !group.isNodesAvailable() && premiumOnly && sessionManager.session?.isUserPro == true {
            return true
        }
        return false
    }
}

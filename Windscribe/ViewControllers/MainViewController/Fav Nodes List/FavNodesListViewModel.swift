//
//  FavNodesListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

enum FavNodesIPAlertType { case connecting; case disconnecting }

protocol FavNodesListViewModelType {
    var presentAlertTrigger: PublishSubject<FavNodesIPAlertType> { get }
    var configureVPNTrigger: PublishSubject<()> { get }

    func setSelectedFavNode(favNode: FavNodeModel)
}

class FavNodesListViewModel: FavNodesListViewModelType {
    var presentAlertTrigger = PublishSubject<FavNodesIPAlertType>()
    var configureVPNTrigger = PublishSubject<()>()

    var logger: FileLogger
    var vpnManager: VPNManager
    var connectivity: Connectivity
    var connectionStateManager: ConnectionStateManagerType

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         connectionStateManager: ConnectionStateManagerType) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.connectionStateManager = connectionStateManager
    }

    func setSelectedFavNode(favNode: FavNodeModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }
        if !connectionStateManager.isConnecting() {
            guard let countryCode = favNode.countryCode,
                  let dnsHostname = favNode.dnsHostname,
                  let hostname = favNode.hostname,
                  let nickName = favNode.nickName,
                  let cityName = favNode.cityName,
                  let ipAddress = favNode.ipAddress,
                  let groupId = Int(favNode.groupId ?? "1") else { return }
            logger.logD(self, "Tapped on Fav Node \(cityName) \(hostname) from the server list.")
            self.vpnManager.selectedNode = SelectedNode(countryCode: countryCode,
                                                        dnsHostname: dnsHostname,
                                                        hostname: hostname,
                                                        serverAddress: ipAddress,
                                                        nickName: nickName,
                                                        cityName: cityName,
                                                        groupId: groupId)
            configureVPNTrigger.onNext(())
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }
}

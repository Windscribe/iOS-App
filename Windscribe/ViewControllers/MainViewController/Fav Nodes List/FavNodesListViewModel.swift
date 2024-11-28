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
    var configureVPNTrigger: PublishSubject<Void> { get }
    var showUpgradeTrigger: PublishSubject<Void> { get }
    func setSelectedFavNode(favNode: FavNodeModel)
}

class FavNodesListViewModel: FavNodesListViewModelType {
    var presentAlertTrigger = PublishSubject<FavNodesIPAlertType>()
    var configureVPNTrigger = PublishSubject<Void>()
    var showUpgradeTrigger = PublishSubject<Void>()

    var logger: FileLogger
    var vpnManager: VPNManager
    var connectivity: Connectivity
    var sessionManager: SessionManagerV2
    let locationsManager: LocationsManagerType

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         sessionManager: SessionManagerV2,
         locationsManager: LocationsManagerType)
    {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.sessionManager = sessionManager
        self.locationsManager = locationsManager
    }

    func setSelectedFavNode(favNode: FavNodeModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }
        if !canAccesstoProLocation() &&
            favNode.isPremiumOnly ?? false
        {
            showUpgradeTrigger.onNext(())
            return
        } else if !vpnManager.isConnecting() {
            guard let hostname = favNode.hostname,
                  let cityName = favNode.cityName,
                  let groupId = Int(favNode.groupId ?? "1") else { return }
            logger.logD(self, "Tapped on Fav Node \(cityName) \(hostname) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(groupId)")

            configureVPNTrigger.onNext(())
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }

    private func canAccesstoProLocation() -> Bool {
        guard let session = sessionManager.session else { return false }
        return session.isPremium
    }
}

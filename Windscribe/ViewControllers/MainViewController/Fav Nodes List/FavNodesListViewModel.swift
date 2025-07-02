//
//  FavouriteListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

enum FavouritesIPAlertType { case connecting; case disconnecting }

protocol FavouriteListViewModelType {
    var presentAlertTrigger: PublishSubject<FavouritesIPAlertType> { get }
    var showUpgradeTrigger: PublishSubject<Void> { get }
    func setSelectedFav(favourite: GroupModel)
}

class FavouriteListViewModel: FavouriteListViewModelType {
    var presentAlertTrigger = PublishSubject<FavouritesIPAlertType>()
    var showUpgradeTrigger = PublishSubject<Void>()

    var logger: FileLogger
    var vpnManager: VPNManager
    var connectivity: Connectivity
    var sessionManager: SessionManaging
    let locationsManager: LocationsManagerType
    let protocolManager: ProtocolManagerType

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         sessionManager: SessionManaging,
         locationsManager: LocationsManagerType,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.sessionManager = sessionManager
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    func setSelectedFav(favourite: GroupModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.configurationState == ConfigurationState.disabling {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }
        if !canAccesstoProLocation() && favourite.premiumOnly {
            showUpgradeTrigger.onNext(())
            return
        } else if vpnManager.configurationState == ConfigurationState.initial {
            logger.logD(self, "Tapped on Favourite \(favourite.city) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(favourite.id)")
            Task {
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }

    private func canAccesstoProLocation() -> Bool {
        guard let session = sessionManager.session else { return false }
        return session.isPremium
    }
}

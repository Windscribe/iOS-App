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
    var vpnStateRepository: VPNStateRepository
    var connectivity: ConnectivityManager
    var sessionRepository: SessionRepository
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType

    init(logger: FileLogger,
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         sessionRepository: SessionRepository,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnStateRepository = vpnStateRepository
        self.connectivity = connectivity
        self.sessionRepository = sessionRepository
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    func setSelectedFav(favourite: GroupModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnStateRepository.configurationState == ConfigurationState.disabling {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }
        if !canAccesstoProLocation() && favourite.premiumOnly {
            showUpgradeTrigger.onNext(())
            return
        } else if vpnStateRepository.configurationState == ConfigurationState.initial {
            logger.logD("FavouriteListViewModel", "Tapped on Favourite \(favourite.city) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(favourite.id)")
            Task {
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }

    private func canAccesstoProLocation() -> Bool {
        guard let session = sessionRepository.session else { return false }
        return session.isPremium
    }
}

//
//  FavouriteListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

enum FavouritesIPAlertType { case connecting; case disconnecting }

protocol FavouriteListViewModelType {
    var presentAlertTrigger: PublishSubject<FavouritesIPAlertType> { get }
    var showMaintenanceLocationTrigger: PassthroughSubject<Void, Never> { get }
    var showUpgradeTrigger: PublishSubject<Void> { get }
    func setSelectedFav(favourite: GroupModel)
}

class FavouriteListViewModel: FavouriteListViewModelType {
    var presentAlertTrigger = PublishSubject<FavouritesIPAlertType>()
    var showMaintenanceLocationTrigger = PassthroughSubject<Void, Never>()
    var showUpgradeTrigger = PublishSubject<Void>()

    var logger: FileLogger
    var vpnStateRepository: VPNStateRepository
    var connectivity: ConnectivityManager
    var userSessionRepository: UserSessionRepository
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType

    init(logger: FileLogger,
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         userSessionRepository: UserSessionRepository,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnStateRepository = vpnStateRepository
        self.connectivity = connectivity
        self.userSessionRepository = userSessionRepository
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    func setSelectedFav(favourite: GroupModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnStateRepository.configurationState == ConfigurationState.disabling {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }
        if checkMaintenanceLocation(favourite: favourite) {
            showMaintenanceLocationTrigger.send()
            return
        }
        if !canAccesstoProLocation() && favourite.premiumOnly {
            showUpgradeTrigger.onNext(())
            return
        } else if vpnStateRepository.configurationState == ConfigurationState.initial {
            logger.logD("FavouriteListViewModel", "Tapped on Favourite \(favourite.city) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(favourite.id)")
            Task {
                self.logger.logI("FavouriteListViewModel", "setSelectedFav for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }

    private func canAccesstoProLocation() -> Bool {
        guard let session = userSessionRepository.sessionModel else { return false }
        return session.isPremium
    }
}

extension FavouriteListViewModel {
    /// Checks if the selected favourite location is under maintenance or has disabled status.
    /// - Parameter favourite: The GroupModel representing the selected favourite location
    /// - Returns: true if location is under maintenance or disabled, false otherwise
    private func checkMaintenanceLocation(favourite: GroupModel) -> Bool {
        // Get the parent server to check status
        guard let location = try? locationsManager.getLocation(from: "\(favourite.id)") else {
            // Location not found in server list - treat as maintenance
            logger.logD("FavouriteListViewModel", "Location not found for favourite \(favourite.id), treating as maintenance")
            return true
        }

        let server = location.0
        let group = location.1

        // Check if server is disabled
        if server.status == false {
            logger.logD("FavouriteListViewModel", "Server \(server.name) is disabled (status=false)")
            return true
        }

        // Check if no nodes available for non-premium locations
        if !group.isNodesAvailable() && !group.premiumOnly {
            logger.logD("FavouriteListViewModel", "No nodes available for non-premium location \(group.city)")
            return true
        }

        // Check if no nodes available for premium locations (when user is premium)
        if !group.isNodesAvailable() && group.premiumOnly &&
            userSessionRepository.sessionModel?.isPremium == true {
            logger.logD("FavouriteListViewModel", "No nodes available for premium location \(group.city)")
            return true
        }

        return false
    }
}

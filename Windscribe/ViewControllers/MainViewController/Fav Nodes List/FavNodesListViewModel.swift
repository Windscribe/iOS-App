//
//  FavouriteListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum FavouritesIPAlertType { case connecting; case disconnecting }

protocol FavouriteListViewModelType {
    var presentAlertTrigger: PassthroughSubject<FavouritesIPAlertType, Never> { get }
    var showMaintenanceLocationTrigger: PassthroughSubject<Void, Never> { get }
    var showUpgradeTrigger: PassthroughSubject<Void, Never> { get }
    func setSelectedFav(favourite: DatacenterModel)
}

class FavouriteListViewModel: FavouriteListViewModelType {
    var presentAlertTrigger = PassthroughSubject<FavouritesIPAlertType, Never>()
    var showMaintenanceLocationTrigger = PassthroughSubject<Void, Never>()
    var showUpgradeTrigger = PassthroughSubject<Void, Never>()

    var logger: FileLogger
    var vpnStateRepository: VPNStateRepository
    var connectivity: ConnectivityManager
    var userSessionRepository: UserSessionRepository
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType
    private let locationListRepository: LocationListRepository

    init(logger: FileLogger,
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         userSessionRepository: UserSessionRepository,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType,
         locationListRepository: LocationListRepository) {
        self.logger = logger
        self.vpnStateRepository = vpnStateRepository
        self.connectivity = connectivity
        self.userSessionRepository = userSessionRepository
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
        self.locationListRepository = locationListRepository
    }

    func setSelectedFav(favourite: DatacenterModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnStateRepository.configurationState == ConfigurationState.disabling {
            presentAlertTrigger.send(.disconnecting)
            return
        }
        if checkMaintenanceLocation(favourite: favourite) {
            showMaintenanceLocationTrigger.send()
            return
        }
        if !userSessionRepository.canAccesstoProLocation(locationId: favourite.locationId),
           favourite.isPremiumOnly {
            showUpgradeTrigger.send(())
            return
        } else if vpnStateRepository.configurationState == ConfigurationState.initial {
            logger.logD("FavouriteListViewModel", "Tapped on Favourite \(favourite.city) from the server list.")
            locationsManager.saveLastConnectionTarget(with: "\(favourite.id)")
            Task {
                self.logger.logI("FavouriteListViewModel", "setSelectedFav for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentAlertTrigger.send(.connecting)
        }
    }
}

extension FavouriteListViewModel {
    /// Checks if the selected favourite location is under maintenance or has disabled status.
    /// - Parameter favourite: The DatacenterModel representing the selected favourite location
    /// - Returns: true if location is under maintenance or disabled, false otherwise
    private func checkMaintenanceLocation(favourite: DatacenterModel) -> Bool {
        let status = favourite.getStatus(hasAccess: userSessionRepository.canAccesstoProLocation(locationId: favourite.locationId))
        if status == .underMantainance { return true }
        return false
    }
}

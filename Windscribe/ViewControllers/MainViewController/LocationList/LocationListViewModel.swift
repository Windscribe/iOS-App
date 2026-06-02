//
//  LocationListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ServerListViewModelType {
    var presentConnectingAlertTrigger: PassthroughSubject<Void, Never> { get }
    var showMaintenanceLocationTrigger: PassthroughSubject<Void, Never> { get }
    var showUpgradeTrigger: PassthroughSubject<Void, Never> { get }
    var reloadTrigger: PassthroughSubject<Void, Never> { get }

    func setSelectedLocationAndDatacenter(location: LocationModel, datacenter: DatacenterModel)
    func connectToBestLocation()
}

class LocationListViewModel: ServerListViewModelType {
    var presentConnectingAlertTrigger = PassthroughSubject<Void, Never>()
    var showMaintenanceLocationTrigger = PassthroughSubject<Void, Never>()
    var showUpgradeTrigger = PassthroughSubject<Void, Never>()
    var reloadTrigger = PassthroughSubject<Void, Never>()

    private let logger: FileLogger
    private let vpnStateRepository: VPNStateRepository
    private let connectivity: ConnectivityManager
    private let userSessionRepository: UserSessionRepository
    private let locationsManager: LocationsManager
    private let protocolManager: ProtocolManagerType
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

    func setSelectedLocationAndDatacenter(location: LocationModel, datacenter: DatacenterModel) {
        if !connectivity.internetConnectionAvailable() {
            return
        }

        if checkMaintenanceLocation(location: location, datacenter: datacenter) {
            showMaintenanceLocationTrigger.send(())
            return
        }

        if !userSessionRepository.canAccesstoProLocation(location: location),
           datacenter.isPremiumOnly {
            showUpgradeTrigger.send(())
            return
        } else if vpnStateRepository.configurationState == ConfigurationState.initial {
            locationsManager.saveLastConnectionTarget(with: "\(datacenter.id)")
            Task {
                self.logger.logI("ServerListViewModel", "setSelectedServerAndGroup for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentConnectingAlertTrigger.send(())
        }
    }

    func connectToBestLocation() {
        let locationId = locationsManager.getBestLocation()
        if  locationId != 0, !self.vpnStateRepository.isConnecting() {
            self.logger.logD("ServerListViewModel", "Tapped on Best Location with ID \(locationId) from the server list.")
            self.locationsManager.selectBestLocation(with: String(locationId))
            Task {
                self.logger.logI("ServerListViewModel", "connectToBestLocation for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            self.presentConnectingAlertTrigger.send(())
        }
    }
}

extension LocationListViewModel {
    /// true: under maintenance
    /// false: not
    private func checkMaintenanceLocation(location: LocationModel, datacenter: DatacenterModel) -> Bool {
        let status = datacenter.getStatus(hasAccess: userSessionRepository.canAccesstoProLocation(location: location))
        if status == .underMantainance { return true }
        return false
    }
}

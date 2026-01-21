//
//  ServerListViewModel.swift
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

    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    func connectToBestLocation()
}

class ServerListViewModel: ServerListViewModelType {
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

    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel) {
        if !connectivity.internetConnectionAvailable() {
            return
        }

        if checkMaintenanceLocation(server: server, group: group) {
            showMaintenanceLocationTrigger.send(())
            return
        }

        if !userSessionRepository.canAccesstoProLocation() && group.premiumOnly {
            showUpgradeTrigger.send(())
            return
        } else if !group.canConnect() {
            reloadTrigger.send(())
        } else if vpnStateRepository.configurationState == ConfigurationState.initial {
            guard let bestNode = group.bestNode else { return }
            logger.logD("ServerListViewModel", "Tapped on a node with groupID: \(group.id) \(bestNode.hostname) from the server list.")
            locationsManager.saveLastSelectedLocation(with: "\(group.id)")
            Task {
                self.logger.logI("ServerListViewModel", "setSelectedServerAndGroup for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentConnectingAlertTrigger.send(())
        }
    }

    func connectToBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnStateRepository.isConnecting() {
            self.logger.logD("ServerListViewModel", "Tapped on Best Location with ID \(locationID) from the server list.")
            self.locationsManager.selectBestLocation(with: locationID)
            Task {
                self.logger.logI("ServerListViewModel", "connectToBestLocation for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            self.presentConnectingAlertTrigger.send(())
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
        if !group.isNodesAvailable() && !group.premiumOnly {
            return true
        } else if !group.isNodesAvailable() && group.premiumOnly &&
                    userSessionRepository.sessionModel?.isPremium == true {
            return true
        }
        return false
    }
}

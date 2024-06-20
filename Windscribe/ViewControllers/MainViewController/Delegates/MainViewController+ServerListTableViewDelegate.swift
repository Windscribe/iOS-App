//
//  MainViewController+ServerListTableViewDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: ServerListTableViewDelegate {
    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel) {
        searchLocationsView.viewModel.dismiss()
        if !ReachabilityManager.shared.internetConnectionAvailable() {
            return
        }

        if vpnManager.isDisconnecting() {
            vpnManagerViewModel.checkConnectedState()
        }
        if checkMaintenanceLocation(server: server, group: group) {
            showMaintenanceLocationView()
            return
        }

        if !canAccesstoProLocation() &&
            group.premiumOnly ?? false {
            showUpgradeView()
            return
        } else if !group.canConnect() {
            reloadTableViews()
        } else if !vpnManagerViewModel.isConnecting() {
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
            LogManager.shared.log(activity: String(describing: MainViewController.self),
                                  text: "Tapped on a node \(serverName) \(bestNodeHostname) from the server list.",
                                  type: .debug)
            vpnManager.selectedNode = SelectedNode(countryCode: countryCode,
                                                   dnsHostname: dnsHostname,
                                                   hostname: hostname,
                                                   serverAddress: serverAddress,
                                                   nickName: nickName,
                                                   cityName: cityName,
                                                   groupId: groupId)
            configureVPN()
        } else {
            displayConnectingAlert()
        }
    }

    /// true: under maintenance
    /// false: not
    func checkMaintenanceLocation(server: ServerModel, group: GroupModel) -> Bool {
        if server.status == false {
            return true
        }
        guard let premiumOnly = group.premiumOnly else {
            return false
        }
        if !group.isNodesAvailable() && !premiumOnly {
            return true
        } else if !group.isNodesAvailable() && premiumOnly && SessionManager.shared.session?.isUserPro == true {
            return true
        }
        return false
    }

    func reloadServerListTableView() {
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.reloadData()
        }
    }

    func connectToBestLocation() {
        searchLocationsView.viewModel.dismiss()
        if !ReachabilityManager.shared.internetConnectionAvailable() { return }
        guard let bestLocation = try? viewModel.bestLocation.value() else { return }
               // PersistenceManager.shared.retrieve(type: BestLocation.self)?.first else { return }
        if !vpnManagerViewModel.isConnecting() {
            LogManager.shared.log(activity: String(describing: MainViewController.self),
                                  text: "Tapped on Best Location \(bestLocation.hostname) from the server list.",
                                  type: .debug)
            vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode,
                                                   dnsHostname: bestLocation.dnsHostname,
                                                   hostname: bestLocation.hostname,
                                                   serverAddress: bestLocation.ipAddress,
                                                   nickName: bestLocation.nickName,
                                                   cityName: bestLocation.cityName,
                                                   groupId: bestLocation.groupId)
            configureVPN()
        } else {
            displayConnectingAlert()
        }
    }
}

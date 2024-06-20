//
//  MainViewController+FavNodesListTableViewDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: FavNodesListTableViewDelegate {

    func setSelectedFavNode(favNode: FavNodeModel) {
        if !ReachabilityManager.shared.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() { self.displayDisconnectingAlert(); return }
        if !vpnManagerViewModel.isConnecting() {
            guard let countryCode = favNode.countryCode,
                  let dnsHostname = favNode.dnsHostname,
                  let hostname = favNode.hostname,
                  let nickName = favNode.nickName,
                  let cityName = favNode.cityName,
                  let ipAddress = favNode.ipAddress,
                  let groupId = Int(favNode.groupId ?? "1") else { return }
            LogManager.shared.log(activity: String(describing: MainViewController.self),
                                  text: "Tapped on Fav Node \(cityName) \(hostname) from the server list.", type: .debug)
            self.vpnManager.selectedNode = SelectedNode(countryCode: countryCode,
                                                        dnsHostname: dnsHostname,
                                                        hostname: hostname,
                                                        serverAddress: ipAddress,
                                                        nickName: nickName,
                                                        cityName: cityName,
                                                        groupId: groupId)
            self.configureVPN()
        } else {
            self.displayConnectingAlert()
        }
    }

    func hideFavNodeRefreshControl() {
        if favTableView.subviews.contains(favTableViewRefreshControl) {
            favTableViewRefreshControl.removeFromSuperview()
        }
    }

    func showFavNodeRefreshControl() {
        if !favTableView.subviews.contains(favTableViewRefreshControl) {
            self.favTableView.addSubview(favTableViewRefreshControl)
        }
    }
}

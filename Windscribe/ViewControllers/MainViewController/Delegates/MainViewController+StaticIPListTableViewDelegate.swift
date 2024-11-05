//
//  MainViewController+StaticIPListTableViewDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: StaticIPListTableViewDelegate {
    func setSelectedStaticIP(staticIP: StaticIPModel) {
        if !ReachabilityManager.shared.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            displayDisconnectingAlert()
            return
        }
        if !vpnManagerViewModel.isConnecting() {
            guard let node = staticIP.bestNode else { return }
            guard let staticIPN = staticIP.staticIP,
                  let countryCode = staticIP.countryCode,
                  let dnsHostname = node.dnsHostname,
                  let hostname = node.hostname, let serverAddress = node.ip2, let nickName = staticIP.staticIP, let cityName = staticIP.cityName, let credentials = staticIP.credentials else { return }
            LogManager.shared.log(activity: String(describing: MainViewController.self),
                                  text: "Tapped on Static IP \(staticIPN) from the server list.", type: .debug)
            vpnManager.selectedNode = SelectedNode(countryCode: countryCode,
                                                   dnsHostname: dnsHostname,
                                                   hostname: hostname,
                                                   serverAddress: serverAddress,
                                                   nickName: nickName,
                                                   cityName: cityName,
                                                   staticIPCredentials: credentials.last,
                                                   groupId: 0)
            configureVPN()
        } else {
            displayConnectingAlert()
        }
    }

    func hideStaticIPRefreshControl() {
        if staticIpTableView.subviews.contains(staticIpTableViewRefreshControl) {
            DispatchQueue.main.async {
                self.staticIpTableViewRefreshControl.removeFromSuperview()
            }
        }
    }

    func showStaticIPRefreshControl() {
        if !staticIpTableView.subviews.contains(staticIpTableViewRefreshControl) {
            DispatchQueue.main.async {
                self.staticIpTableView.addSubview(self.staticIpTableViewRefreshControl)
            }
        }
    }
}

//
//  MainViewController+StaticIP.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

extension MainViewController: StaticIPListTableViewDelegate {
    func reloadStaticIPListTableView() {
        staticIpTableView.reloadData()
    }

    func addStaticIP() {
        staticIPListViewModel.addStaticIP()
    }

    func setSelectedStaticIP(staticIP: StaticIPModel) {
        staticIPListViewModel.setSelectedStaticIP(staticIP: staticIP)
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

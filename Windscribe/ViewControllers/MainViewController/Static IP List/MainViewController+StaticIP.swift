//
//  MainViewController+StaticIP.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

extension MainViewController {
    func bindStaticIPListViewModel() {
        staticIPListViewModel.presentLinkTrigger.subscribe {
            self.openLink(url: $0)
        }.disposed(by: disposeBag)
        staticIPListViewModel.presentAlertTrigger.subscribe {
            switch $0 {
            case .connecting: self.displayConnectingAlert()
            case .disconnecting: self.displayDisconnectingAlert()
            }
        }.disposed(by: disposeBag)
        staticIPListViewModel.configureVPNTrigger.subscribe { _ in
            self.configureVPN()
        }.disposed(by: disposeBag)
    }
}

extension MainViewController: StaticIPListTableViewDelegate {
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

//
//  MainViewController+ServerList.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

extension MainViewController {
    func bindServerListViewModel() {
        serverListViewModel.presentConnectingAlertTrigger.subscribe { _ in
            self.displayConnectingAlert()
        }.disposed(by: disposeBag)
        serverListViewModel.configureVPNTrigger.subscribe { _ in
            self.configureVPN()
        }.disposed(by: disposeBag)
        serverListViewModel.showMaintenanceLocationTrigger.subscribe { _ in
            self.showMaintenanceLocationView()
        }.disposed(by: disposeBag)
        serverListViewModel.showUpgradeTrigger.subscribe { _ in
            self.showUpgradeView()
        }.disposed(by: disposeBag)
        serverListViewModel.reloadTrigger.subscribe { _ in
            self.reloadTableViews()
        }.disposed(by: disposeBag)
    }
}

extension MainViewController: ServerListTableViewDelegate {
    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    {
        searchLocationsView.viewModel.dismiss()
        serverListViewModel.setSelectedServerAndGroup(server: server,
                                                      group: group)
    }

    func connectToBestLocation() {
        searchLocationsView.viewModel.dismiss()
        serverListViewModel.connectToBestLocation()
    }

    func reloadServerListTableView() {
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.reloadData()
        }
    }
}

//
//  MainViewController+LoadData.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit
import Combine

extension MainViewController {
    func loadPortMap() {
        let appProtocols = TextsAsset.General.protocols.sorted()
        viewModel.portMapHeadings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] headings in
                guard let self = self else { return }
                let portMapProvidedProtocols = (headings ?? []).sorted()
                if appProtocols != portMapProvidedProtocols {
                    self.viewModel.loadPortMap()
                }
            }
            .store(in: &cancellables)
    }

    @objc func reloadFavouriteOrder() {
        viewModel.favouriteList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favList in
                guard let self = self else { return }
                if favList?.count == 0 {
                    favoriteListTableViewDataSource.updateFavoriteList(with: [])
                }
                if let favList = favList {
                    let orderedFavList = viewModel.sortFavouriteNodesUsingUserPreferences(favList: favList)
                    favoriteListTableViewDataSource.updateFavoriteList(with: orderedFavList)
                }

            }
            .store(in: &cancellables)
    }

    func loadStaticIPs() {
        viewModel.staticIPs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let staticIPModels = self.viewModel.getStaticIp()
                self.staticIPListTableViewDataSource.updateStaticIPList(with: staticIPModels)
                self.loadStaticIPLatencyValues()
            }
            .store(in: &cancellables)
    }

    func loadCustomConfigs() {
        logger.logD("MainViewController", "Loading custom configs list from disk.")
        viewModel.customConfigs
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] customConfigs in
                self?.customConfigListTableViewDataSource.updateCustomConfigList(with: customConfigs)
            })
            .store(in: &cancellables)
    }

    func loadStaticIPLatencyValues() {
        viewModel.loadStaticIPLatencyValues(completion: { [weak self] _, error in
            if error == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.staticIpTableView.reloadData()
                }
            }
        })
    }

    func loadCustomConfigLatencyValues() {
        viewModel.loadCustomConfigLatencyValues { [weak self] _, error in
            if error == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.customConfigTableView.reloadData()
                }
            }
        }
    }

    func loadLatencyValues(force: Bool = false, connectToBestLocation: Bool = false) {
        viewModel.latencies
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.vpnConnectionViewModel.isDisconnected() || force ||
                    self.isAnyRefreshControlIsRefreshing() {
                    Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        if self.vpnConnectionViewModel.isDisconnected(),
                           self.vpnConnectionViewModel.isBestLocationSelected(),
                           connectToBestLocation {
                            self.latencyLoadTimeOutWithSelectAndConnectBestLocation()
                        } else {
                            self.latencyLoadTimeOut()
                        }
                    }
                } else {
                    self.logger.logD("MainViewController", "Connected to VPN Stopping latency refresh.")
                    self.endRefreshControls()
                }
            }
            .store(in: &cancellables)
    }
}

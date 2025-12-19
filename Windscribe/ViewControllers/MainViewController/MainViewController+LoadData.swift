//
//  MainViewController+LoadData.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import UIKit

extension MainViewController {
    func loadLastConnection() {
        viewModel.lastConnection.subscribe(onNext: { [weak self] lastconnection in
            self?.connectionStateInfoView.updateProtoPort(ProtocolPort(
                lastconnection?.protocolType ?? "",
                lastconnection?.port ?? ""
            ))
        }).disposed(by: disposeBag)
    }

    func loadPortMap() {
        let appProtocols = TextsAsset.General.protocols.sorted()
        viewModel.portMapHeadings.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] headings in
            guard let self = self else { return }
            // Now we're working with plain strings - no Realm threading issues
            let portMapProvidedProtocols = (headings ?? []).sorted()
            if appProtocols != portMapProvidedProtocols {
                self.viewModel.loadServerList()
                self.viewModel.loadPortMap()
            }
        }).disposed(by: disposeBag)
    }

    @objc func reloadFavouriteOrder() {
        viewModel.favouriteList.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] favList in
            guard let self = self else { return }
            if favList?.count == 0 {
                favNodesListTableViewDataSource.updateFavoriteList(with: [])
            }
            if let favList = favList {
                let orderedFavList = viewModel.sortFavouriteNodesUsingUserPreferences(favList: favList)
                favNodesListTableViewDataSource.updateFavoriteList(with: orderedFavList)
            }

        }, onError: { [weak self] error in
            self?.logger.logE("MainViewController", "Realm server list notification error \(error.localizedDescription)")

        }).disposed(by: disposeBag)
    }

    func loadStaticIPs() {
        viewModel.staticIPs.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                var staticIPModels = [StaticIPModel]()
                let staticips = self.viewModel.getStaticIp()
                for result in staticips {
                    guard let staticIPModel = result.getStaticIPModel() else { return }
                    staticIPModels.append(staticIPModel)
                }
                self.staticIPListTableViewDataSource.updateStaticIPList(with: staticIPModels)
                self.loadStaticIPLatencyValues()
            }

        }, onError: { [weak self] error in
            self?.logger.logE("MainViewController", "Realm static ip list notification error \(error.localizedDescription)")
        }).disposed(by: disposeBag)
    }

    func loadCustomConfigs() {
        logger.logD("MainViewController", "Loading custom configs list from disk.")
        viewModel.customConfigs.subscribe(on: MainScheduler.instance).observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] customconfigs in
            guard let self = self else { return }
            var customConfigs = [CustomConfigModel]()
            guard let customconfigs = customconfigs else { return }
            for result in customconfigs where !result.isInvalidated {
                customConfigs.append(result.getModel())
            }
            customConfigListTableViewDataSource.updateCustomConfigList(with: customConfigs)
        }, onError: { [weak self] error in
            self?.logger.logE("MainViewController", "Realm custom config list notification error \(error.localizedDescription)")
        }).disposed(by: disposeBag)
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
        viewModel.latencies.subscribe(onNext: { [weak self] _ in
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
        }).disposed(by: disposeBag)
    }
}

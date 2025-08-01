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
        viewModel.lastConnection.subscribe(onNext: { lastconnection in
            self.connectionStateInfoView.updateProtoPort(ProtocolPort(
                lastconnection?.protocolType ?? "",
                lastconnection?.port ?? ""
            ))
        }).disposed(by: disposeBag)
    }

    func loadPortMap() {
        let appProtocols = TextsAsset.General.protocols.sorted()
        viewModel.portMap.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { portMaps in
            let portMapProvidedProtocols = (portMaps?.map { $0.heading } ?? []).sorted()
            if appProtocols != portMapProvidedProtocols {
                self.viewModel.loadServerList()
                self.viewModel.loadPortMap()
            }
        }).disposed(by: disposeBag)
    }

    func loadFavouriteList() {
        favTableView.dataSource = favNodesListTableViewDataSource
        favTableView.delegate = favNodesListTableViewDataSource
        favNodesListTableViewDataSource?.delegate = self
        reloadFavouriteOrder()
    }

    @objc func reloadFavouriteOrder() {
        viewModel.favouriteList.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] favList in
                if favList?.count == 0 {
                    favNodesListTableViewDataSource = FavouriteListTableViewDataSource(favList: [], viewModel: viewModel)
                favTableView.dataSource = favNodesListTableViewDataSource
                favTableView.reloadData()
                return
            }
            if let favList = favList {
                favNodesListTableViewDataSource = FavouriteListTableViewDataSource(favList: viewModel.sortFavouriteNodesUsingUserPreferences(favList: favList), viewModel: viewModel)
                favNodesListTableViewDataSource?.delegate = self
                favTableView.dataSource = favNodesListTableViewDataSource
                favTableView.delegate = favNodesListTableViewDataSource
                DispatchQueue.main.async { [weak self] in
                    self?.favTableView.reloadData()
                    self?.serverListTableView.reloadData()
                }
            }

        }, onError: { error in
            self.logger.logE("MainViewController", "Realm server list notification error \(error.localizedDescription)")

        }).disposed(by: disposeBag)
    }

    func loadStaticIPs() {
        viewModel.staticIPs.subscribe(onNext: { [self] _ in
            DispatchQueue.main.async {
                var staticIPModels = [StaticIPModel]()
                let staticips = self.viewModel.getStaticIp()
                for result in staticips {
                    guard let staticIPModel = result.getStaticIPModel() else { return }
                    staticIPModels.append(staticIPModel)
                }
                self.staticIPListTableViewDataSource = StaticIPListTableViewDataSource(staticIPs: staticIPModels, viewModel: self.viewModel)
                self.staticIPListTableViewDataSource?.delegate = self
                self.staticIPListTableViewDataSource?.makeEmptyView(tableView: self.staticIpTableView)
                self.staticIpTableView.dataSource = self.staticIPListTableViewDataSource
                self.staticIpTableView.delegate = self.staticIPListTableViewDataSource
                self.staticIpTableView.reloadData()
                self.staticIPTableViewFooterView.delegate = self.staticIPListViewModel
                self.staticIPTableViewFooterView.updateDeviceName()
                self.loadStaticIPLatencyValues()
            }

        }, onError: { [self] error in
            self.logger.logE("MainViewController", "Realm static ip list notification error \(error.localizedDescription)")
        }).disposed(by: disposeBag)
    }

    func loadCustomConfigs() {
        logger.logD("MainViewController", "Loading custom configs list from disk.")
        viewModel.customConfigs.subscribe(on: MainScheduler.instance).observe(on: MainScheduler.instance).subscribe(onNext: { [self] customconfigs in
            var customConfigs = [CustomConfigModel]()
            guard let customconfigs = customconfigs else { return }
            for result in customconfigs where !result.isInvalidated {
                customConfigs.append(result.getModel())
            }
            self.customConfigListTableViewDataSource = CustomConfigListTableViewDataSource(customConfigs: customConfigs, viewModel: viewModel)
            customConfigListTableViewDataSource?.uiDelegate = self
            customConfigListTableViewDataSource?.logicDelegate = customConfigPickerViewModel
            self.customConfigTableView.dataSource = self.customConfigListTableViewDataSource
            self.customConfigTableView.delegate = self.customConfigListTableViewDataSource
            self.customConfigTableView.reloadData()
        }, onError: { [self] error in
            self.logger.logE("MainViewController", "Realm custom config list notification error \(error.localizedDescription)")
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
        viewModel.latencies.subscribe(onNext: { _ in
            if self.vpnConnectionViewModel.isDisconnected() || force ||
                self.isAnyRefreshControlIsRefreshing() {
                if self.vpnConnectionViewModel.isBestLocationSelected(), connectToBestLocation {
                    Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.latencyLoadTimeOutWithSelectAndConnectBestLocation), userInfo: nil, repeats: false)
                } else {
                    Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.latencyLoadTimeOut), userInfo: nil, repeats: false)
                }
            } else {
                self.logger.logD("MainViewController", "Connected to VPN Stopping latency refresh.")
                self.endRefreshControls()
            }
        }).disposed(by: disposeBag)
    }
}

//
//  MainViewController+LoadData.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import RxSwift

extension MainViewController {
    func loadLastConnection() {
        viewModel.lastConnection.subscribe(onNext: { lastconnection in
            self.protocolLabel.text = lastconnection?.protocolType
            self.portLabel.text = lastconnection?.port
        }).disposed(by: disposeBag)

    }

    func loadPortMap() {
        let appProtocols = TextsAsset.General.protocols.sorted()
        viewModel.portMap.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { portMaps in
            let portMapProvidedProtocols = (portMaps?.map { return $0.heading } ?? []).sorted()
            if appProtocols != portMapProvidedProtocols {
                self.logger.logD(self, "Updating Portmap to include missing protocols.")
                self.viewModel.loadServerList()
                self.viewModel.loadPortMap()
                self.loadLastConnected()
            } else {
                self.logger.logD(self, "Updated Portmap is avaialble.")
            }
        }).disposed(by: disposeBag)
    }

    func loadFavNodes() {
        favTableView.dataSource = favNodesListTableViewDataSource
        favTableView.delegate = favNodesListTableViewDataSource
        favNodesListTableViewDataSource?.delegate = self
        reloadFavNodeOrder()

    }

    @objc func reloadFavNodeOrder() {
        viewModel.favNode.subscribe(onNext: { [self] favNodes in
            if favNodes?.count == 0 {
                favNodesListTableViewDataSource = FavNodesListTableViewDataSource(favNodes: [], viewModel: viewModel)
                favTableView.dataSource = favNodesListTableViewDataSource
                favTableView.reloadData()
                return
            }
            var favNodeModels = [FavNodeModel]()
            if let favnodes = favNodes {
                for result in favnodes {
                    guard let favNodeModel = result.getFavNodeModel() else { return }
                    favNodeModels.append(favNodeModel)
                }
                favNodesListTableViewDataSource = FavNodesListTableViewDataSource(favNodes: viewModel.sortFavouriteNodesUsingUserPreferences(favNodes: favNodeModels), viewModel: viewModel)
                favNodesListTableViewDataSource?.delegate = self
                favTableView.dataSource = favNodesListTableViewDataSource
                favTableView.delegate = favNodesListTableViewDataSource
                favTableView.reloadData()
                serverListTableView.reloadData()
            }

        }, onError: { error in
            self.logger.logE(self, "Realm server list notification error \(error.localizedDescription)")

        }).disposed(by: disposeBag)
    }

    func loadStaticIPs() {
        self.viewModel.staticIPs.subscribe(onNext: { [self] staticips in
            DispatchQueue.main.async {
                var staticIPModels = [StaticIPModel]()
                let staticips = self.viewModel.getStaticIp()
                for result in staticips {
                    guard let staticIPModel = result.getStaticIPModel() else { return }
                    staticIPModels.append(staticIPModel)
                }
                self.staticIPListTableViewDataSource = StaticIPListTableViewDataSource(staticIPs: staticIPModels, viewModel: self.viewModel)
                self.staticIPListTableViewDataSource?.delegate = self
                self.staticIpTableView.dataSource = self.staticIPListTableViewDataSource
                self.staticIpTableView.delegate = self.staticIPListTableViewDataSource
                self.staticIpTableView.reloadData()
                self.staticIPTableViewFooterView.delegate = self.staticIPListViewModel
                self.staticIPTableViewFooterView.updateDeviceName()
                self.loadStaticIPLatencyValues()
            }

        }, onError: { [self] error in
            self.logger.logE(self, "Realm static ip list notification error \(error.localizedDescription)")
        }).disposed(by: self.disposeBag)

    }

    func loadCustomConfigs() {
        logger.logD(self, "Loading custom configs list from disk.")
        self.viewModel.customConfigs.subscribe(on: MainScheduler.instance).observe(on: MainScheduler.instance).subscribe(onNext: { [self] customconfigs in
            var customConfigs = [CustomConfigModel]()
            guard let customconfigs = customconfigs else { return }
            for result in customconfigs {
                customConfigs.append(result.getModel())
            }
            self.customConfigListTableViewDataSource = CustomConfigListTableViewDataSource(customConfigs: customConfigs, viewModel: viewModel)
            customConfigListTableViewDataSource?.uiDelegate = self
            customConfigListTableViewDataSource?.logicDelegate = customConfigPickerViewModel
            self.customConfigTableView.dataSource = self.customConfigListTableViewDataSource
            self.customConfigTableView.delegate = self.customConfigListTableViewDataSource
            self.customConfigTableView.reloadData()
        }, onError: { [self] error in
            self.logger.logE(self, "Realm custom config list notification error \(error.localizedDescription)")
        }).disposed(by: self.disposeBag)
    }

    func loadStaticIPLatencyValues() {
        viewModel.loadStaticIPLatencyValues(completion: { [weak self] (_, error) in
            if error == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.staticIpTableView.reloadData()
                }
            }
        })
    }

    func loadCustomConfigLatencyValues() {
        viewModel.loadCustomConfigLatencyValues { [weak self] (_, error) in
            if error == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.customConfigTableView.reloadData()
                }
            }
        }
    }

    func loadLatencyValues(force: Bool = false, selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        viewModel.latencies.subscribe(onNext: { _ in
            if self.vpnManager.isDisconnected() || force ||
                self.isAnyRefreshControlIsRefreshing() {
                if let observer = self.latencyLoaderObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                if selectBestLocation && connectToBestLocation {
                    Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.latencyLoadTimeOutWithSelectAndConnectBestLocation), userInfo: nil, repeats: false)
                } else {
                    Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.latencyLoadTimeOut), userInfo: nil, repeats: false)
                }
            } else {
                self.logger.logD(self, "Connected to VPN Stopping latency refresh.")
                self.endRefreshControls()
            }
        }).disposed(by: disposeBag)

    }

    func loadNotifications() {
        viewModel.notices.observe(on: MainScheduler.asyncInstance).subscribe( onNext: { _ in
            self.checkForUnreadNotifications()
        }, onError: { error in
            self.logger.logE(self, "Realm notifications error \(error.localizedDescription)")
        }).disposed(by: disposeBag)
    }
}

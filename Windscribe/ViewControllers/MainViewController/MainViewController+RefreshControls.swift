//
//  MainViewController+RefreshControls.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-22.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

extension MainViewController {
    @objc func handleRefresh() {
        if VPNManager.shared.isConnected() || VPNManager.shared.isConnecting() {
            self.endRefreshControls(update: false)
            return
        }
        if isRefreshing == false && isLoadingLatencyValues == false {
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if vpnManager.isDisconnectedAndNotConfigured() || isOnline {
                self.beginRefreshControls()
                self.isRefreshing = true
                self.isLoadingLatencyValues = true
                self.hideTextOnRefreshControls()
                latencyViewModel.loadAllServerLatency().observe(on: MainScheduler.asyncInstance).subscribe(onCompleted: {
                    self.serverListTableView.reloadData()
                    self.favTableView.reloadData()
                    self.streamingTableView.reloadData()
                    self.staticIpTableView.reloadData()
                    self.customConfigTableView.reloadData()
                    self.isRefreshing = false
                    self.isLoadingLatencyValues = false
                    self.endRefreshControls(update: false)
                }, onError: { _ in
                    self.isRefreshing = false
                    self.isLoadingLatencyValues = false
                    self.endRefreshControls(update: false)
                }).disposed(by: disposeBag)
            } else {
                self.endRefreshControls(update: false)
            }
        }
    }

    func hideTextOnRefreshControls() {
        self.serverListTableView.refreshControl?.attributedTitle = nil
        favTableViewRefreshControl.attributedTitle = nil
        streamingTableViewRefreshControl.attributedTitle = nil
        staticIpTableViewRefreshControl.attributedTitle = nil
        customConfigsTableViewRefreshControl.attributedTitle = nil
    }

    func beginRefreshControls() {
        serverListTableView.refreshControl?.beginRefreshing()
        self.favTableViewRefreshControl.beginRefreshing()
        self.streamingTableViewRefreshControl.beginRefreshing()
        self.staticIpTableViewRefreshControl.beginRefreshing()
        self.customConfigsTableViewRefreshControl.beginRefreshing()
    }

    func endRefreshControls(update: Bool = true) {
        isServerListLoading = false
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.refreshControl?.endRefreshing()
            self?.favTableViewRefreshControl.endRefreshing()
            self?.streamingTableViewRefreshControl.endRefreshing()
            self?.staticIpTableViewRefreshControl.endRefreshing()
            self?.customConfigsTableViewRefreshControl.endRefreshing()
        }

        if update {
            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateRefreshControls), userInfo: nil, repeats: false)
        }
    }

    @objc func updateRefreshControls() {
        if vpnManager.isDisconnectedAndNotConfigured() {
            if let serverRefreshControl = self.serverListTableView.refreshControl as? WSRefreshControl {
                self.showRefreshControlDisconnectedState(serverRefreshControl)
            }
            self.showRefreshControlDisconnectedState(self.favTableViewRefreshControl)
            self.showRefreshControlDisconnectedState(self.streamingTableViewRefreshControl)
            self.showRefreshControlDisconnectedState(self.staticIpTableViewRefreshControl)
            self.showRefreshControlDisconnectedState(self.customConfigsTableViewRefreshControl)
        } else {
            if let serverRefreshControl = self.serverListTableView.refreshControl as? WSRefreshControl {
                self.showRefreshControlConnectedState(serverRefreshControl)
            }
            self.showRefreshControlConnectedState(self.favTableViewRefreshControl)
            self.showRefreshControlConnectedState(self.streamingTableViewRefreshControl)
            self.showRefreshControlConnectedState(self.staticIpTableViewRefreshControl)
            self.showRefreshControlConnectedState(self.customConfigsTableViewRefreshControl)
        }
    }

    private func showRefreshControlConnectedState(_ refreshControl: WSRefreshControl) {
        refreshControl.subviews.first?.subviews[2].isHidden = false
        refreshControl.subviews.first?.subviews[0].isHidden = true
        refreshControl.subviews.first?.subviews[1].isHidden = true
    }

    private func showRefreshControlDisconnectedState(_ refreshControl: WSRefreshControl) {
        refreshControl.setText(TextsAsset.refreshLatency)
        refreshControl.subviews.first?.subviews[2].isHidden = true
        refreshControl.subviews.first?.subviews[0].isHidden = false
        refreshControl.subviews.first?.subviews[1].isHidden = false
    }

    func isAnyRefreshControlIsRefreshing() -> Bool {
        return self.serverListTableView.refreshControl?.isRefreshing ?? false || self.favTableViewRefreshControl.isRefreshing || self.streamingTableViewRefreshControl.isRefreshing || self.staticIpTableViewRefreshControl.isRefreshing || self.customConfigsTableViewRefreshControl.isRefreshing
    }

    func addRefreshControls() {
        serverListTableViewRefreshControl.resetText()
        self.serverListTableView.refreshControl = serverListTableViewRefreshControl
        if (favNodesListTableViewDataSource?.favNodes?.count ?? 0) > 0 {
            self.favTableView.addSubview(favTableViewRefreshControl)
        }
        self.streamingTableView.addSubview(streamingTableViewRefreshControl)
        self.staticIpTableView.addSubview(staticIpTableViewRefreshControl)
        self.customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
    }

    func removeRefreshControls() {
        serverListTableView.refreshControl = nil
        favTableViewRefreshControl.removeFromSuperview()
        streamingTableViewRefreshControl.removeFromSuperview()
        staticIpTableViewRefreshControl.removeFromSuperview()
        customConfigsTableViewRefreshControl.removeFromSuperview()
    }

}

// MARK: Extension for handling server refresh controller in background mode
extension MainViewController {
    public func beginRefreshingServerList() {
        if serverListTableView.refreshControl == nil {
            serverListTableView.refreshControl = serverListTableViewRefreshControl
        }
        serverListTableView.refreshControl?.beginRefreshing()
        isServerListLoading = true
    }

    @objc
    open func serverRefreshControlValueChanged() {
        if isRefreshing == false {
            isServerListLoading = true
            handleRefresh()
        }
    }

    @objc
    func applicationWillEnterForeground() {
        logger.logD(self, "Application will enter foreground")
        restartServerRefreshControl()
    }

    func restartServerRefreshControl() {
        if isServerListLoading {
            if serverListTableView.refreshControl == nil {
                serverListTableView.refreshControl = serverListTableViewRefreshControl
            }
            serverListTableView.refreshControl?.attributedTitle = nil
            serverListTableView.refreshControl?.beginRefreshing()
        }
    }

}

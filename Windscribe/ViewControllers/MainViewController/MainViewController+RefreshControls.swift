//
//  MainViewController+RefreshControls.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-22.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

extension MainViewController {
    @objc func handleRefresh() {
        if connectionStateViewModel.vpnManager.isConnected() || connectionStateViewModel.vpnManager.isConnecting() {
            endRefreshControls(update: false)
            return
        }
        if isRefreshing == false, isLoadingLatencyValues == false {
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if connectionStateViewModel.vpnManager.isDisconnectedAndNotConfigured() || isOnline {
                beginRefreshControls()
                isRefreshing = true
                isLoadingLatencyValues = true
                hideTextOnRefreshControls()
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
                endRefreshControls(update: false)
            }
        }
    }

    func hideTextOnRefreshControls() {
        serverListTableView.refreshControl?.attributedTitle = nil
        favTableViewRefreshControl.attributedTitle = nil
        streamingTableViewRefreshControl.attributedTitle = nil
        staticIpTableViewRefreshControl.attributedTitle = nil
        customConfigsTableViewRefreshControl.attributedTitle = nil
    }

    func beginRefreshControls() {
        serverListTableView.refreshControl?.beginRefreshing()
        favTableViewRefreshControl.beginRefreshing()
        streamingTableViewRefreshControl.beginRefreshing()
        staticIpTableViewRefreshControl.beginRefreshing()
        customConfigsTableViewRefreshControl.beginRefreshing()
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
        if connectionStateViewModel.vpnManager.isDisconnectedAndNotConfigured() {
            if let serverRefreshControl = serverListTableView.refreshControl as? WSRefreshControl {
                showRefreshControlDisconnectedState(serverRefreshControl)
            }
            showRefreshControlDisconnectedState(favTableViewRefreshControl)
            showRefreshControlDisconnectedState(streamingTableViewRefreshControl)
            showRefreshControlDisconnectedState(staticIpTableViewRefreshControl)
            showRefreshControlDisconnectedState(customConfigsTableViewRefreshControl)
        } else {
            if let serverRefreshControl = serverListTableView.refreshControl as? WSRefreshControl {
                showRefreshControlConnectedState(serverRefreshControl)
            }
            showRefreshControlConnectedState(favTableViewRefreshControl)
            showRefreshControlConnectedState(streamingTableViewRefreshControl)
            showRefreshControlConnectedState(staticIpTableViewRefreshControl)
            showRefreshControlConnectedState(customConfigsTableViewRefreshControl)
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
        return serverListTableView.refreshControl?.isRefreshing ?? false || favTableViewRefreshControl.isRefreshing || streamingTableViewRefreshControl.isRefreshing || staticIpTableViewRefreshControl.isRefreshing || customConfigsTableViewRefreshControl.isRefreshing
    }

    func addRefreshControls() {
        serverListTableViewRefreshControl.resetText()
        serverListTableView.refreshControl = serverListTableViewRefreshControl
        if (favNodesListTableViewDataSource?.favNodes?.count ?? 0) > 0 {
            favTableView.addSubview(favTableViewRefreshControl)
        }
        streamingTableView.addSubview(streamingTableViewRefreshControl)
        staticIpTableView.addSubview(staticIpTableViewRefreshControl)
        customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
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

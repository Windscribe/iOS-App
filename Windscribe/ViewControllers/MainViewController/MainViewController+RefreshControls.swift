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
        if vpnConnectionViewModel.isConnected() || vpnConnectionViewModel.isConnecting() {
            endRefreshControls(update: false)
            return
        }
        if isRefreshing == false, isLoadingLatencyValues == false {
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if vpnConnectionViewModel.isDisconnected() || isOnline {
                beginRefreshControls()
                isRefreshing = true
                isLoadingLatencyValues = true
                hideTextOnRefreshControls()

                latencyViewModel.loadAllServerLatency(
                    onAllServerCompletion: { [weak self] in
                        guard let self else { return }

                        self.loadServerTable(servers: (try? self.viewModel.serverList.value()) ?? [])
                        self.favTableView.reloadData()
                        self.endRefreshControls(update: false)
                    }, onStaticCompletion: { [weak self] in
                        guard let self else { return }

                        self.loadStaticIPs()
                        self.staticIpTableView.reloadData()
                        self.endRefreshControls(update: false)
                    }, onCustomConfigCompletion: {  [weak self] in
                        guard let self else { return }

                        self.customConfigTableView.reloadData()
                        self.endRefreshControls(update: false)
                    },
                    onExitCompletion: { [weak self] in
                        guard let self, self.isRefreshing else { return }

                        self.isRefreshing = false
                        self.isLoadingLatencyValues = false
                    })
            } else {
                endRefreshControls(update: false)
            }
        }
    }

    func hideTextOnRefreshControls() {
        serverListTableView.refreshControl?.attributedTitle = nil
        favTableViewRefreshControl.attributedTitle = nil
        staticIpTableViewRefreshControl.attributedTitle = nil
        customConfigsTableViewRefreshControl.attributedTitle = nil
    }

    func beginRefreshControls() {
        serverListTableView.refreshControl?.beginRefreshing()
        favTableViewRefreshControl.beginRefreshing()
        staticIpTableViewRefreshControl.beginRefreshing()
        customConfigsTableViewRefreshControl.beginRefreshing()
    }

    func endRefreshControls(update: Bool = true) {
        isServerListLoading = false
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.refreshControl?.endRefreshing()
            self?.favTableViewRefreshControl.endRefreshing()
            self?.staticIpTableViewRefreshControl.endRefreshing()
            self?.customConfigsTableViewRefreshControl.endRefreshing()
        }

        if update {
            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateRefreshControls), userInfo: nil, repeats: false)
        }
    }

    @objc func updateRefreshControls() {
        if vpnConnectionViewModel.isDisconnected() {
            if let serverRefreshControl = serverListTableView.refreshControl as? WSRefreshControl {
                showRefreshControlDisconnectedState(serverRefreshControl)
            }
            showRefreshControlDisconnectedState(favTableViewRefreshControl)
            showRefreshControlDisconnectedState(staticIpTableViewRefreshControl)
            showRefreshControlDisconnectedState(customConfigsTableViewRefreshControl)
        } else {
            if let serverRefreshControl = serverListTableView.refreshControl as? WSRefreshControl {
                showRefreshControlConnectedState(serverRefreshControl)
            }
            showRefreshControlConnectedState(favTableViewRefreshControl)
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
        return serverListTableView.refreshControl?.isRefreshing ?? false || favTableViewRefreshControl.isRefreshing || staticIpTableViewRefreshControl.isRefreshing || customConfigsTableViewRefreshControl.isRefreshing
    }

    func addRefreshControls() {
        serverListTableViewRefreshControl.resetText()
        serverListTableView.refreshControl = serverListTableViewRefreshControl
        if favNodesListTableViewDataSource.favList.count > 0 {
            favTableView.addSubview(favTableViewRefreshControl)
        }
        staticIpTableView.addSubview(staticIpTableViewRefreshControl)
        customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
    }

    func removeRefreshControls() {
        serverListTableView.refreshControl = nil
        favTableViewRefreshControl.removeFromSuperview()
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
        logger.logD("MainViewController", "Application will enter foreground")
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

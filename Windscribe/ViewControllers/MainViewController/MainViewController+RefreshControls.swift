//
//  MainViewController+RefreshControls.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-22.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit

extension MainViewController {
    @objc func handleRefresh() {
        if vpnConnectionViewModel.isConnected() || vpnConnectionViewModel.isConnecting() {
            endRefreshControls(update: false)
            return
        }
        if isRefreshing == false, isLoadingLatencyValues == false {
            let isOnline: Bool = viewModel.appNetwork.value.status == .connected
            if vpnConnectionViewModel.isDisconnected() || isOnline {
                beginRefreshControls()
                isRefreshing = true
                isLoadingLatencyValues = true
                hideTextOnRefreshControls()

                latencyViewModel.loadAllServerLatency(
                    onAllServerCompletion: { [weak self] in
                        guard let self else { return }
                        DispatchQueue.main.async {
                            self.favTableView.reloadData()
                        }
                    }, onStaticCompletion: { [weak self] in
                        guard let self else { return }

                        self.loadStaticIPs()
                        DispatchQueue.main.async {
                            self.staticIpTableView.reloadData()
                        }
                    }, onCustomConfigCompletion: {  [weak self] in
                        guard let self else { return }
                        DispatchQueue.main.async {
                            self.customConfigTableView.reloadData()
                        }
                    },
                    onExitCompletion: { [weak self] in
                        guard let self, self.isRefreshing else { return }
                        self.isRefreshing = false
                        self.endRefreshControls(update: false)
                        self.isLoadingLatencyValues = false
                    })
            } else {
                endRefreshControls(update: false)
            }
        }
    }

    func hideTextOnRefreshControls() {
        locationsListTableView.refreshControl?.attributedTitle = nil
        favTableViewRefreshControl.attributedTitle = nil
        staticIpTableViewRefreshControl.attributedTitle = nil
        customConfigsTableViewRefreshControl.attributedTitle = nil
    }

    func beginRefreshControls() {
        locationsListTableView.refreshControl?.beginRefreshing()
        favTableViewRefreshControl.beginRefreshing()
        staticIpTableViewRefreshControl.beginRefreshing()
        customConfigsTableViewRefreshControl.beginRefreshing()
    }

    func endRefreshControls(update: Bool = true) {
        isServerListLoading = false
        DispatchQueue.main.async { [weak self] in
            self?.locationsListTableView.refreshControl?.endRefreshing()
            self?.favTableViewRefreshControl.endRefreshing()
            self?.staticIpTableViewRefreshControl.endRefreshing()
            self?.customConfigsTableViewRefreshControl.endRefreshing()
        }

        if update {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.updateRefreshControls()
            }
        }
    }

    func updateRefreshControls() {
        if vpnConnectionViewModel.isDisconnected() {
            if let serverRefreshControl = locationsListTableView.refreshControl as? WSRefreshControl {
                showRefreshControlDisconnectedState(serverRefreshControl)
            }
            showRefreshControlDisconnectedState(favTableViewRefreshControl)
            showRefreshControlDisconnectedState(staticIpTableViewRefreshControl)
            showRefreshControlDisconnectedState(customConfigsTableViewRefreshControl)
        } else {
            if let serverRefreshControl = locationsListTableView.refreshControl as? WSRefreshControl {
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
        return locationsListTableView.refreshControl?.isRefreshing ?? false || favTableViewRefreshControl.isRefreshing || staticIpTableViewRefreshControl.isRefreshing || customConfigsTableViewRefreshControl.isRefreshing
    }

    func addRefreshControls() {
        locationsListTableViewRefreshControl.resetText()
        locationsListTableView.refreshControl = locationsListTableViewRefreshControl
        if favoriteListTableViewDataSource.favList.count > 0 {
            favTableView.addSubview(favTableViewRefreshControl)
        }
        staticIpTableView.addSubview(staticIpTableViewRefreshControl)
        customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
    }

    func removeRefreshControls() {
        locationsListTableView.refreshControl = nil
        favTableViewRefreshControl.removeFromSuperview()
        staticIpTableViewRefreshControl.removeFromSuperview()
        customConfigsTableViewRefreshControl.removeFromSuperview()
    }
}

// MARK: Extension for handling server refresh controller in background mode

extension MainViewController {
    public func beginRefreshingServerList() {
        if locationsListTableView.refreshControl == nil {
            locationsListTableView.refreshControl = locationsListTableViewRefreshControl
        }
        locationsListTableView.refreshControl?.beginRefreshing()
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
            if locationsListTableView.refreshControl == nil {
                locationsListTableView.refreshControl = locationsListTableViewRefreshControl
            }
            locationsListTableView.refreshControl?.attributedTitle = nil
            locationsListTableView.refreshControl?.beginRefreshing()
        }
    }
}

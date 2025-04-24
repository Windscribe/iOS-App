//
//  MainViewController+Selector.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import RxSwift
import UIKit

extension MainViewController {
    @objc func checkForUnreadNotifications() {
        viewModel.checkForUnreadNotifications(completion: { showNotifications, readNoticeDifferentCount in
            DispatchQueue.main.async {
                if showNotifications {
                    self.showNotificationsViewController()
                }
                if readNoticeDifferentCount != 0 {
                    self.notificationDot.setTitle("\(readNoticeDifferentCount)", for: .normal)
                    if self.notificationDot.titleLabel?.text != nil {
                        self.notificationDot.isHidden = false
                    }
                } else {
                    self.notificationDot.isHidden = true
                }
            }
        })
    }

    @objc func latencyLoadTimeOut(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        if isLoadingLatencyValues {
            print("Loading latency timed out.")
            isLoadingLatencyValues = false
            configureBestLocation(selectBestLocation: selectBestLocation, connectToBestLocation: connectToBestLocation)
            reloadTableViews()
            hideSplashView()
            endRefreshControls()
        }
    }

    @objc func latencyLoadTimeOutWithSelectAndConnectBestLocation() {
        latencyLoadTimeOut(selectBestLocation: true, connectToBestLocation: true)
    }

    @objc func configureBestLocationDefault() {
        if serverListTableViewDataSource?.bestLocation == nil, noSelectedNodeToConnect() {
            configureBestLocation(selectBestLocation: true, connectToBestLocation: false)
            reloadServerList()
        } else {
            configureBestLocation(selectBestLocation: false, connectToBestLocation: false)
            reloadServerList()
        }
    }

    func updateUIForSession(session: Session?) {
        logger.logD(self, "Looking for account state changes.")
        guard let session = session else { return }

        // check for ghost account and present account completion screen
        if didCheckForGhostAccount == false, session.isUserPro == true, session.isUserGhost == true {
            didCheckForGhostAccount = true
            router?.routeTo(to: RouteID.signup(claimGhostAccount: true), from: self)
        }

        arrangeListsFooterViews()
        reloadTableViews()
        setTableViewInsets()
        if session.status == 3 {
            logger.logD(self, "User is banned.")
            var animated = true
            if let topVc = navigationController?.topViewController as? AccountPopupViewController {
                if topVc is BannedAccountPopupViewController {
                    return
                }
                topVc.dismiss(animated: false)
                animated = false
            }
            popupRouter?.routeTo(to: RouteID.bannedAccountPopup(animated: animated), from: self)
            return
        } else if session.status == 2 {
            logger.logD(self, "User is out of data.")
            if !didShowOutOfDataPopup {
                showOutOfDataPopup()
                didShowOutOfDataPopup = true
            }
        }

        guard let oldSession = viewModel.oldSession else { return }
        if !session.isPremium, oldSession.isPremium {
            if !didShowProPlanExpiredPopup {
                showProPlanExpiredPopup()
                didShowProPlanExpiredPopup = true
            }
        }
    }

    func refreshProtocol(from network: WifiNetwork?, with protoPort: ProtocolPort?) {
        DispatchQueue.main.async {
            self.wifiInfoView.updateNetwork(network: network)
            if network?.isInvalidated == true {
                return
            }
            let isNetworkCellularWhileConnecting = self.vpnConnectionViewModel.isNetworkCellularWhileConnecting(for: network)
//            self.connectionStateInfoView.refreshProtocol(from: network, with: protoPort,
//                                                         isNetworkCellularWhileConnecting: isNetworkCellularWhileConnecting)
        }
    }

    func showConnectionFailed() {
        AlertManager.shared.showSimpleAlert(viewController: self,
                                            title: TextsAsset.UnableToConnect.title,
                                            message: TextsAsset.UnableToConnect.message,
                                            buttonText: TextsAsset.okay)
    }

    func showAuthFailurePopup() {
        AlertManager.shared.showSimpleAlert(viewController: self,
                                            title: TextsAsset.AuthFailure.title,
                                            message: TextsAsset.AuthFailure.message,
                                            buttonText: TextsAsset.okay)
    }

    @objc func reloadTableViews() {
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.reloadData()
            self?.favTableView.reloadData()
            self?.staticIpTableView.reloadData()
            self?.customConfigTableView.reloadData()
        }
    }

    @objc func disableVPNConnection() {
        vpnConnectionViewModel.disableConnection()
    }

    @objc func enableVPNConnection() {
        vpnConnectionViewModel.enableConnection()
    }

    @objc func reloadServerListOrder() {
        guard let results = try? viewModel.serverList.value() else { return }
        if results.count == 0 { return }
        DispatchQueue.main.async {
            self.loadServerTable(servers: results)
            self.reloadFavNodeOrder()
            self.configureBestLocation()
        }
    }

    @objc func loadServerList() {
        viewModel.locationOrderBy.subscribe(on: MainScheduler.instance).bind(onNext: { _ in
            DispatchQueue.main.async {
                self.loadServerTable(servers: (try? self.viewModel.serverList.value()) ?? [])
            }
        }).disposed(by: disposeBag)
        reloadFavNodeOrder()
        viewModel.serverList.subscribe(on: MainScheduler.instance).subscribe(onNext: { [self] _ in
            DispatchQueue.main.async {
                self.loadServerTable(servers: (try? self.viewModel.serverList.value()) ?? [])
            }
        }).disposed(by: disposeBag)
    }

    func loadServerTable(servers: [ServerModel], shouldColapse: Bool = false, reloadFinishedCompletion: (() -> Void)? = nil) {
        viewModel.sortServerListUsingUserPreferences(isForStreaming: false, servers: servers) { serverSectionsOrdered in
            self.serverListTableViewDataSource = ServerListTableViewDataSource(serverSections: serverSectionsOrdered, viewModel: self.viewModel, shouldColapse: shouldColapse)
            self.serverListTableViewDataSource?.delegate = self
            self.serverListTableView.dataSource = self.serverListTableViewDataSource
            self.serverListTableView.delegate = self.serverListTableViewDataSource
            if let bestLocation = self.vpnConnectionViewModel.getBestLocation() {
                self.serverListTableViewDataSource?.bestLocation = bestLocation
            }
            reloadFinishedCompletion?()
            DispatchQueue.main.async {
                self.serverListTableView.reloadData()
                self.reloadServerList()
            }
        }
    }

    @objc func disconnectVPNIntentReceived() {
        logger.logD(self, "Disconnect intent received from outside of the app.")
        disableVPNConnection()
    }

    @objc func connectVPNIntentReceived() {
        logger.logD(self, "Connect intent received from outside of the app.")
        enableVPNConnection()
    }

    func connectButtonTapped() {
        HapticFeedbackGenerator.shared.run(level: .medium)
        if vpnConnectionViewModel.isDisconnected() || vpnConnectionViewModel.isDisconnecting() {
            logger.logI(MainViewController.self, "User tapped to connect.")
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if isOnline {
                customSoundPlaybackManager.playSound(for: .connect)
                enableVPNConnection()
            } else {
                displayInternetConnectionLostAlert()
            }
        } else {
            logger.logD(self, "User tapped to disconnect.")
            customSoundPlaybackManager.playSound(for: .disconnect)
            vpnConnectionViewModel.disableConnection()
        }
    }

    @objc func loadLatencyWhenReady() {
        if vpnConnectionViewModel.isInvalid() { return }
        sessionManager.keepSessionUpdated()
        if appJustStarted {
            appJustStarted = false
            vpnConnectionViewModel.displayLocalIPAddress()
            if vpnConnectionViewModel.isDisconnected() {
                loadLatencyValues()
                return
            }
        }
        reloadTableViews()
        hideSplashView()
        configureBestLocation()
    }

    @objc func reachabilityChanged() {
        checkForInternetConnection()
        if vpnConnectionViewModel.isDisconnected() {
            vpnConnectionViewModel.displayLocalIPAddress()
        }
        WifiManager.shared.saveCurrentWifiNetworks()
        viewModel.updateSSID()
    }

    @objc func popoverDismissed() {
        UIView.animate(withDuration: 0.25) {
            self.view.layer.opacity = 1.0
        }
    }

    func logoButtonTapped() {
        logger.logD(self, "User tapped to view Preferences view.")
        //  HapticFeedbackGenerator.shared.run(level: .medium)
        router?.routeTo(to: RouteID.mainMenu, from: self)
    }

    @objc func notificationsButtonTapped() {
        logger.logD(self, "User tapped to view Notifications view.")
        showNotificationsViewController()
    }

    @objc func upgradeButtonTapped() {
        logger.logD(self, "User tapped upgrade button.")
        showUpgradeView()
    }
}

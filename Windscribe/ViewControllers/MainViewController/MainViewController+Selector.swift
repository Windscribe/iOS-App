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

    func updateUIForSession(session: SessionModel?) {
        logger.logD("MainViewController", "Looking for account state changes.")
        guard let session = session else { return }

        // Check for ghost account and present account completion screen
        showAccountCompletionForGhostAccount(session: session)

        proIcon.isHidden = !session.isUserPro

        arrangeListsFooterViews()
        reloadTableViews()
        setTableViewInsets()

        if session.status == 3 {
            logger.logI("MainViewController", "User is banned from servers.")

            if !didShowBannedProfilePopup {
                showBannedAccountPopup()
                didShowBannedProfilePopup = true
                return
            }
        }

        if session.status == 2 {
            logger.logI("MainViewController", "User is out of data.")

            if !didShowOutOfDataPopup {
                showOutOfDataPopup()
                didShowOutOfDataPopup = true
                return
            }
        }

        guard let oldSession = viewModel.oldSession else { return }
        if !session.isPremium, oldSession.isPremium {
            if !didShowProPlanExpiredPopup {
                showProPlanExpiredPopup()
                didShowProPlanExpiredPopup = true
                return
            }
        }
    }

    func checkEligibility(session: SessionModel?, isStaticIP: Bool) -> Bool {
        guard let session = session else {
            return false
        }

        if session.status == 3 {
            showBannedAccountPopup()
            return false
        }

        if session.status == 2, !isStaticIP {
            showOutOfDataPopup()
            return false
        }

        if let oldSession = viewModel.oldSession, !session.isPremium, oldSession.isPremium, !isStaticIP {
            showProPlanExpiredPopup()
            return false
        }

        return true
    }

    func showBannedAccountPopup() {
        logger.logI("MainViewController", "Displaying Banned User Profile Popup.")
        popupRouter?.routeTo(to: RouteID.bannedAccountPopup, from: self)
    }

    func showOutOfDataPopup() {
        logger.logI("MainViewController", "Displaying Out Of Data Popup.")
        popupRouter?.routeTo(to: RouteID.outOfDataAccountPopup, from: self)
    }

    func showProPlanExpiredPopup() {
        logger.logI("MainViewController", "Displaying Pro Plan Expired Popup.")
        popupRouter?.routeTo(to: RouteID.proPlanExpireddAccountPopup, from: self)
    }

    func showAccountCompletionForGhostAccount(session: SessionModel) {
        if didCheckForGhostAccount == false, session.isUserPro == true, session.isUserGhost == true {
            logger.logI("MainViewController", "Displaying Account Completion Popup for Ghost Account.")
            didCheckForGhostAccount = true
            router?.routeTo(to: RouteID.signup(claimGhostAccount: true), from: self)
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

    func refreshProtocol(from network: WifiNetwork?, with protoPort: ProtocolPort?) {
        DispatchQueue.main.async {
            self.wifiInfoView.updateNetwork(network: network)
            if network?.isInvalidated == true {
                return
            }
            let isNetworkCellularWhileConnecting = self.vpnConnectionViewModel.isNetworkCellularWhileConnecting(for: network)
            self.connectionStateInfoView.refreshProtocol(from: network, with: protoPort,
                                                         isNetworkCellularWhileConnecting: isNetworkCellularWhileConnecting)
            if self.vpnConnectionViewModel.isConnecting() {
                self.connectButtonView.viewModel?.refreshConnectingState()
            }
        }
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
            self.reloadFavouriteOrder()
            self.configureBestLocation()
        }
    }

    @objc func loadServerList() {
        viewModel.locationOrderBy.subscribe(on: MainScheduler.instance).bind(onNext: { _ in
            DispatchQueue.main.async {
                self.loadServerTable(servers: (try? self.viewModel.serverList.value()) ?? [])
            }
        }).disposed(by: disposeBag)
        reloadFavouriteOrder()
        viewModel.serverList.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] servers in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadServerTable(servers: servers)
            }
        }).disposed(by: disposeBag)
    }

    func loadServerTable(servers: [ServerModel], shouldColapse: Bool = false, reloadFinishedCompletion: (() -> Void)? = nil) {
        viewModel.sortServerListUsingUserPreferences(ignoreStreaming: true, isForStreaming: false, servers: servers) { serverSectionsOrdered in
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
        logger.logD("MainViewController", "Disconnect intent received from outside of the app.")
        disableVPNConnection()
    }

    @objc func connectVPNIntentReceived() {
        logger.logD("MainViewController", "Connect intent received from outside of the app.")
        enableVPNConnection()
    }

    func connectButtonTapped() {
        viewModel.runHapticFeedback(level: .medium)
        if vpnConnectionViewModel.isDisconnected() || vpnConnectionViewModel.isDisconnecting() {
            logger.logI("MainViewController", "User tapped to connect.")

            // Check eligibility EXCEPT for custom config
            let isCustomConfig = vpnConnectionViewModel.isCustomConfigSelected()
            if !isCustomConfig {
                let session = try? viewModel.sessionModel.value()
                let locationType = vpnConnectionViewModel.getLocationType()
                let isStaticIP = (locationType == .staticIP)

                guard checkEligibility(session: session, isStaticIP: isStaticIP) else {
                    return
                }
            }

            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if isOnline {
                enableVPNConnection()
            } else {
                displayInternetConnectionLostAlert()
            }
        } else {
            logger.logD("MainViewController", "User tapped to disconnect.")
            vpnConnectionViewModel.disableConnection()
        }
    }

    @objc func loadLatencyWhenReady() {
        if vpnConnectionViewModel.isInvalid() { return }
        viewModel.keepSessionUpdated()
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
        logger.logD("MainViewController", "User tapped to view Preferences view.")
        // viewModel.runHapticFeedback(level: .medium)
        router?.routeTo(to: RouteID.mainMenu, from: self)
    }

    @objc func notificationsButtonTapped() {
        logger.logD("MainViewController", "User tapped to view Notifications view.")
        showNotificationsViewController()
    }

    @objc func upgradeButtonTapped() {
        logger.logD("MainViewController", "User tapped upgrade button.")
        showUpgradeView()
    }
}

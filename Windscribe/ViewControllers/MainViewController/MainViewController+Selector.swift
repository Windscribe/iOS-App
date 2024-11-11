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
import RxRealm
import RxSwift

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

        getMoreDataLabel.text = "\(session.getDataLeft()) \(TextsAsset.left.uppercased())"
        arrangeDataLeftViews()
        reloadTableViews()
        setTableViewInsets()
        if session.status == 3 {
            logger.logD(self, "User is banned.")
            var animated = true
            if let topVc = navigationController?.topViewController as? AccountPopupViewController {
                if topVc as? BannedAccountPopupViewController != nil {
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
        } else if session.getDataUsedInMB() >= 1024, viewModel.daysSinceLogin() >= 2, viewModel.showRateDialog() {
            logger.logD(self, "Showing rating dialog with Used data: \(session.getDataUsedInMB()) MB Logged In days: \(viewModel.daysSinceLogin()) Should show rate dialog: \(viewModel.showRateDialog())")
            showRateUsPopup()
        }
        logger.logD(self, "Used data: \(session.getDataUsedInMB()) MB Logged In days: \(viewModel.daysSinceLogin()) Should show rate dialog: \(viewModel.showRateDialog())")
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
            guard !self.vpnConnectionViewModel.isDisconnecting() else { return }
            guard let protoPort = protoPort else {
                self.setPreferredProtocolBadgeVisibility(hidden: true)
                return
            }
            self.protocolLabel.text = protoPort.protocolName
            self.portLabel.text = protoPort.portName
            
            if self.vpnConnectionViewModel.isConnected() || self.vpnConnectionViewModel.isConnecting() {
                self.setPreferredProtocolBadgeVisibility(hidden: !(network?.preferredProtocolStatus ?? false))
                return
            }
            if WifiManager.shared.selectedPreferredProtocolStatus ?? false, WifiManager.shared.selectedPreferredProtocol == protoPort.protocolName, WifiManager.shared.selectedPreferredPort == protoPort.portName {
                self.setPreferredProtocolBadgeVisibility(hidden: false)
            } else {
                self.setPreferredProtocolBadgeVisibility(hidden: true)
            }
        }
    }

    private func setPreferredProtocolBadgeVisibility(hidden: Bool) {
        DispatchQueue.main.async {
            if hidden {
                self.preferredBadgeConstraints[2].constant = 0
                self.preferredBadgeConstraints[3].constant = 0
            } else {
                self.preferredBadgeConstraints[2].constant = 10
                self.preferredBadgeConstraints[3].constant = 8
            }
            self.preferredProtocolBadge.layoutIfNeeded()
            self.changeProtocolArrow.layoutIfNeeded()
        }
    }

    func showConnectionFailed() {
        AlertManager.shared.showSimpleAlert(viewController: self,
                                            title: TextsAsset.UnableToConnect.title,
                                            message: TextsAsset.UnableToConnect.message,
                                            buttonText: TextsAsset.okay)
    }

    @objc func reloadTableViews() {
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.reloadData()
            self?.favTableView.reloadData()
            self?.streamingTableView.reloadData()
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
            let serverModels = results.compactMap { $0.getServerModel() }
            let serverSections: [ServerSection] = serverModels.filter { $0.isForStreaming() == false }.map { ServerSection(server: $0, collapsed: true) }
            let streamingSections: [ServerSection] = serverModels.filter { $0.isForStreaming() == true }.map { ServerSection(server: $0, collapsed: true) }
            let serverSectionsOrdered = self.sortServerListUsingUserPreferences(serverSections: serverSections)
            let streamingSectionsOrdered = self.sortServerListUsingUserPreferences(serverSections: streamingSections)

            self.serverListTableViewDataSource?.serverSections = serverSectionsOrdered
            self.sortedServerList = serverSectionsOrdered
            self.streamingTableViewDataSource?.streamingSections = streamingSectionsOrdered

            self.serverListTableView.reloadData()
            self.streamingTableView.reloadData()
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

    func loadServerTable(servers: [Server]) {
        viewModel.sortServerListUsingUserPreferences(isForStreaming: false, servers: servers) { serverSectionsOrdered in
            self.serverListTableViewDataSource = ServerListTableViewDataSource(serverSections: serverSectionsOrdered, viewModel: self.viewModel)
            self.serverListTableViewDataSource?.delegate = self
            self.serverListTableView.dataSource = self.serverListTableViewDataSource
            self.serverListTableView.delegate = self.serverListTableViewDataSource
            if let bestLocation = try? self.viewModel.bestLocation.value(), bestLocation.isInvalidated == false {
                self.serverListTableViewDataSource?.bestLocation = bestLocation.getBestLocationModel()
            }
        }
        viewModel.sortServerListUsingUserPreferences(isForStreaming: true, servers: servers) { streamingSectionsOrdered in
            self.streamingTableViewDataSource = StreamingListTableViewDataSource(streamingSections: streamingSectionsOrdered, viewModel: self.viewModel)
            self.streamingTableViewDataSource?.delegate = self
            self.streamingTableView.dataSource = self.streamingTableViewDataSource
            self.streamingTableView.delegate = self.streamingTableViewDataSource
            DispatchQueue.main.async {
                self.streamingTableView.reloadData()
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

    @objc func connectButtonTapped() {
        HapticFeedbackGenerator.shared.run(level: .medium)
        if statusLabel.text?.contains(TextsAsset.Status.off) ?? false {
            logger.logE(MainViewController.self, "User tapped to connect.")
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if isOnline {
                vpnConnectionViewModel.enableConnection()
            } else {
                displayInternetConnectionLostAlert()
            }
        } else {
            logger.logD(self, "User tapped to disconnect.")
            vpnConnectionViewModel.disableConnection()
        }
    }

    @objc func expandButtonTapped() {
        if expandButton.tag == 0 {
            locationManagerViewModel.requestLocationPermission {
                self.showAutoSecureViews()
            }
        } else {
            hideAutoSecureViews()
            WifiManager.shared.saveCurrentWifiNetworks()
            guard let result = WifiManager.shared.getConnectedNetwork() else { return }
            let nextProtocol = ConnectionManager.shared.getNextProtocol()
            if vpnConnectionViewModel.isConnected(), nextProtocol.protocolName != result.preferredProtocol || nextProtocol.portName != result.preferredPort {
                enableVPNConnection()
            } else {
                viewModel.refreshProtocolInfo()
            }
        }
    }

    @objc func loadLatencyWhenReady() {
        guard let observer = latencyLoaderObserver else { return }
        if vpnConnectionViewModel.isInvalid() { return }
        NotificationCenter.default.removeObserver(observer)
        sessionManager.keepSessionUpdated()
        if appJustStarted, vpnConnectionViewModel.isDisconnected() {
            connectionStateViewModel.displayLocalIPAddress()
            loadLatencyValues()
        } else {
            reloadTableViews()
            hideSplashView()
            configureBestLocation()
        }
    }

    @objc func reachabilityChanged() {
        checkForInternetConnection()
        if !vpnConnectionViewModel.isConnected() {
            connectionStateViewModel.displayLocalIPAddress()
        }
        WifiManager.shared.saveCurrentWifiNetworks()
        setNetworkSsid()
        viewModel.refreshProtocolInfo()
    }

    @objc func popoverDismissed() {
        UIView.animate(withDuration: 0.25) {
            self.view.layer.opacity = 1.0
        }
    }

    @objc func logoButtonTapped() {
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

    @objc func protocolPortLableTapped() {
        openConnectionChangeDialog()
    }
}

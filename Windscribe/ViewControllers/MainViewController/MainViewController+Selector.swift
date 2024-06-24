//
//  MainViewController+Selector.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import NetworkExtension
import RxRealm
import RxSwift

extension MainViewController {
    @objc func appEnteredForeground() {
        if VPNManager.shared.isConnecting() && !internetConnectionLost {
            logger.logD(self, "Recovery: App entered foreground while connecting. Will restart connection.")
            configureVPN(bypassConnectingCheck: true)
        }
        clearScrollHappened()
        connectionStateViewModel.becameActive()
        let connectionCount = viewModel.getConnectionCount() ?? 0
        if connectionCount >= 1 {
            connectivityTestTimer?.invalidate()
            connectivityTestTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                         target: self,
                                                         selector: #selector(runConnectivityTestWithNewNodeOnFail),
                                                         userInfo: nil,
                                                         repeats: false)
        }
        sessionManager.keepSessionUpdated()
        guard let lastNotificationTimestamp = viewModel.getLastNotificationTimestamp() else {
            viewModel.saveLastNotificationTimestamp()
            return
        }
        if Date().timeIntervalSince1970 - lastNotificationTimestamp >= 3600 {
            viewModel.saveLastNotificationTimestamp()
            checkForNewNotifications()
        }
        updateServerConfigs()
        checkAndShowShareDialogIfNeed()
        handleShortcutLaunch()
    }

    @objc func runConnectivityTestWithNewNodeOnFail() {
        if vpnManager.isConnected() {
            vpnManager.runConnectivityTest(connectToAnotherNode: true, checkForIPAddressChange: false)
        }
    }

    @objc func checkForUnreadNotifications() {
        viewModel.checkForUnreadNotifications(completion: { showNotifications,readNoticeDifferentCount in
            if showNotifications {
                DispatchQueue.main.async {
                    self.showNotificationsViewController()
                }
            }
            if readNoticeDifferentCount != 0 {
                DispatchQueue.main.async {
                    self.notificationDot.setTitle("\(readNoticeDifferentCount)", for: .normal)
                    if self.notificationDot.titleLabel?.text != nil {
                        self.notificationDot.isHidden = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.notificationDot.isHidden = true
                }
            }
        })
    }

    @objc func checkForNewNotifications() {
        logger.logD(self, "Checking for new notifications.")
        viewModel.loadNotifications()
    }

    @objc func latencyLoadTimeOut(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        if self.isLoadingLatencyValues {
            print("Loading latency timed out.")
            self.isLoadingLatencyValues = false
            self.configureBestLocation(selectBestLocation: selectBestLocation, connectToBestLocation: connectToBestLocation)
            self.reloadTableViews()
            self.hideSplashView()
            self.endRefreshControls()
        }
    }

    @objc func latencyLoadTimeOutWithSelectAndConnectBestLocation() {
        self.latencyLoadTimeOut(selectBestLocation: true, connectToBestLocation: true)
    }

    @objc func configureBestLocationDefault() {
        if self.serverListTableViewDataSource?.bestLocation == nil && self.noSelectedNodeToConnect() {
            self.configureBestLocation(selectBestLocation: true, connectToBestLocation: false)
            self.reloadServerList()
        } else {
            self.configureBestLocation(selectBestLocation: false, connectToBestLocation: false)
            self.reloadServerList()
        }
    }

    func updateUIForSession(session: Session?) {
        logger.logD(self, "Looking for account state changes.")
        guard let session = session, !session.isInvalidated else { return }
        // check for ghost account and present account completion screen
        if didCheckForGhostAccount == false && session.isUserPro == true && session.isUserGhost == true {
            self.didCheckForGhostAccount = true
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
                self.showOutOfDataPopup()
                self.didShowOutOfDataPopup = true
            }
        } else if session.getDataLeftInMB() >= 1024 && appJustStarted == false && viewModel.showRateDialog() {
            self.showRateUsPopup()
        }
        guard let oldSession =   viewModel.oldSession else { return }
        if !session.isPremium && oldSession.isPremium {
            if !didShowProPlanExpiredPopup {
                self.showProPlanExpiredPopup()
                self.didShowProPlanExpiredPopup = true
            }
        }
    }

    func refreshProtocol(from network: WifiNetwork?) {
        self.vpnManager.getVPNConnectionInfo { [self] info in
            if info != nil && [NEVPNStatus.connected, NEVPNStatus.connecting].contains(info!.status) {
                protocolLabel.text = info?.selectedProtocol
                portLabel.text = info?.selectedPort
                if let network = network, network.preferredProtocolStatus {
                    self.setPreferredProtocolBadgeVisibility(hidden: false)
                } else {
                    self.setPreferredProtocolBadgeVisibility(hidden: true)
                }
                return
            }
            if self.vpnManager.isCustomConfigSelected() {
                guard let customConfig = self.vpnManager.selectedNode?.customConfig else { return }
                self.protocolLabel.text = customConfig.protocolType
                self.portLabel.text = customConfig.port
                self.setPreferredProtocolBadgeVisibility(hidden: true)
                return
            }
            if self.vpnManager.isFromProtocolFailover || self.vpnManager.isFromProtocolChange {
                if WifiManager.shared.selectedPreferredProtocolStatus ?? false && WifiManager.shared.selectedPreferredProtocol == self.protocolLabel.text && WifiManager.shared.selectedPreferredPort == self.portLabel.text {
                    self.setPreferredProtocolBadgeVisibility(hidden: false)
                } else {
                    self.setPreferredProtocolBadgeVisibility(hidden: true)
                }
                let nextProtocolToConnect = ConnectionManager.shared.getNextProtocol()
                self.protocolLabel.text = nextProtocolToConnect.protocolName
                self.portLabel.text = nextProtocolToConnect.portName
                return
            }
            if let network = network, network.preferredProtocolStatus {
                self.setPreferredProtocolBadgeVisibility(hidden: false)
                self.protocolLabel.text = network.preferredProtocol
                self.portLabel.text = network.preferredPort
                return
            } else {
                self.setPreferredProtocolBadgeVisibility(hidden: true)
            }
            if ((try? self.viewModel.connectionMode.value()) ?? DefaultValues.connectionMode) == Fields.Values.manual {
                self.setPreferredProtocolBadgeVisibility(hidden: true)
                self.protocolLabel.text = try? self.viewModel.selectedProtocol.value()
                self.portLabel.text = try? self.viewModel.selectedPort.value()
                return
            }
            self.protocolLabel.text = WifiManager.shared.selectedProtocol ?? protocolLabel.text
            self.portLabel.text = WifiManager.shared.selectedPort ?? portLabel.text
        }
    }

    private func setPreferredProtocolBadgeVisibility(hidden: Bool) {
        if hidden {
            print("Badge is Hidden ####")
            preferredBadgeConstraints[2].constant = 0
            preferredBadgeConstraints[3].constant = 0
        } else {
            print("Badge is unhidden $$$$$$")
            preferredBadgeConstraints[2].constant = 10
            preferredBadgeConstraints[3].constant = 8
        }
        preferredProtocolBadge.layoutIfNeeded()
        changeProtocolArrow.layoutIfNeeded()
    }

    @objc func showConnectionFailed() {
        if vpnManager.isDisconnected() {
            AlertManager.shared.showSimpleAlert(viewController: self,
                                                title: TextsAsset.UnableToConnect.title,
                                                message: TextsAsset.UnableToConnect.message,
                                                buttonText: TextsAsset.okay)
        }
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

    @objc func configureVPN(bypassConnectingCheck: Bool = false) {
        if !viewModel.isPrivacyPopupAccepted() {
            showPrivacyConfirmationPopup()
            return
        } else if vpnManager.isConnecting() && bypassConnectingCheck == false {
            self.displayConnectingAlert()
            logger.logD(self, "User attempted to connect while in connecting state.")

            return
        } else if sessionManager.session?.status == 2 && !vpnManager.isCustomConfigSelected() {
            self.showOutOfDataPopup()
            vpnManager.disconnectActiveVPNConnection(setDisconnect: true, disableConnectIntent: true)
            logger.logD(self, "User attempted to connect when out of data.")
            return
        }
        vpnManager.connectIntent = false
        vpnManager.userTappedToDisconnect = false
        vpnManager.isOnDemandRetry = false
        if WifiManager.shared.isConnectedWifiTrusted() {
            router?.routeTo(to: .trustedNetwork, from: self)
        } else {
            viewModel.reconnect()
        }
    }

    @objc func reloadServerListOrder() {
        guard let results = try? viewModel.serverList.value() else { return }
        if results.count == 0 { return }
        DispatchQueue.main.async {
            let serverModels = results.compactMap({ $0.getServerModel() })
            let serverSections: [ServerSection] = serverModels.filter({ $0.isForStreaming() == false }).map({ ServerSection(server: $0, collapsed: true) })
            let streamingSections: [ServerSection] = serverModels.filter({ $0.isForStreaming() == true }).map({ ServerSection(server: $0, collapsed: true) })
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

    @objc func loadLastConnected() {
        if let node = viewModel.getLastConnectedNode(), let nodeModel = node.getFavNodeModel() {
            guard let countryCode = nodeModel.countryCode, let dnsHostname = nodeModel.dnsHostname, let hostname = nodeModel.hostname, let serverAddress = nodeModel.ipAddress, let nickName = nodeModel.nickName, let cityName = nodeModel.cityName, let groupId = Int(nodeModel.groupId ?? "1") else { return }
            self.vpnManager.selectedNode = SelectedNode(countryCode: countryCode, dnsHostname: dnsHostname, hostname: hostname, serverAddress: serverAddress, nickName: nickName, cityName: cityName, staticIPCredentials: node.staticIPCredentials.first?.getModel(), customConfig: viewModel.getCustomConfig(customConfigID: node.customConfigId), groupId: groupId)
            if (self.vpnManager.selectedNode?.wgPublicKey == nil || self.vpnManager.selectedNode?.ip3 == nil) && node.customConfigId == nil && vpnManager.isDisconnected() {
                if self.vpnManager.selectedNode?.cityName == Fields.Values.bestLocation {
                    self.configureBestLocation()
                } else {
                    self.vpnManager.selectAnotherNode()
                }
                logger.logD(self, "Last connected node couldn't be found on disk. Loading another node in same group.")
            }

            if let customConfigId = node.customConfigId, let customConfig = try? viewModel.customConfigs.value()?.first(where: { $0.id == customConfigId }) {
                self.vpnManager.selectedNode?.customConfig = customConfig.getModel()
            }
            logger.logD(self, "Last connected node retrived from disk. \( self.vpnManager.selectedNode?.hostname ?? "")")
        }
        if self.vpnManager.selectedNode == nil {
            guard let bestLocation = try? viewModel.bestLocation.value()?.getBestLocationModel() else { return }
            guard let countryCode = bestLocation.countryCode, let dnsHostname = bestLocation.dnsHostname, let hostname = bestLocation.hostname, let serverAddress = bestLocation.ipAddress, let nickName = bestLocation.nickName, let cityName = bestLocation.cityName, let groupId = bestLocation.groupId else { return }
            self.vpnManager.selectedNode = SelectedNode(countryCode: countryCode, dnsHostname: dnsHostname, hostname: hostname, serverAddress: serverAddress, nickName: nickName, cityName: cityName, groupId: groupId)
            logger.logD(self, "Last connected node couldn't be found on disk. Best location node is set as selected.")

        }
    }

    @objc func loadServerList() {
        self.viewModel.locationOrderBy.subscribe(on: MainScheduler.instance).bind(onNext: { _ in
            DispatchQueue.main.async {
                self.loadServerTable(servers: (try? self.viewModel.serverList.value()) ?? [])
            }
        }).disposed(by: self.disposeBag)
        self.reloadFavNodeOrder()
        self.viewModel.serverList.subscribe(on: MainScheduler.instance).subscribe( onNext: { [self] _ in
            DispatchQueue.main.async {
                self.loadServerTable(servers: (try? self.viewModel.serverList.value()) ?? [])
            }
        }).disposed(by: self.disposeBag)
    }

    func loadServerTable(servers: [Server]) {
        self.viewModel.sortServerListUsingUserPreferences(isForStreaming: false, servers: servers) { serverSectionsOrdered in
            self.serverListTableViewDataSource = ServerListTableViewDataSource(serverSections: serverSectionsOrdered, viewModel: self.viewModel)
            self.serverListTableViewDataSource?.delegate = self
            self.serverListTableView.dataSource = self.serverListTableViewDataSource
            self.serverListTableView.delegate = self.serverListTableViewDataSource
            if let bestLocation = try? self.viewModel.bestLocation.value(), bestLocation.isInvalidated == false {
                self.serverListTableViewDataSource?.bestLocation = bestLocation.getBestLocationModel()
            }
        }
        self.viewModel.sortServerListUsingUserPreferences(isForStreaming: true, servers: servers) { streamingSectionsOrdered in
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

        if vpnManager.isConnected() {
            disconnectVPN()
        }
    }

    @objc func connectVPNIntentReceived() {
        logger.logD(self, "Connect intent received from outside of the app.")
        if vpnManager.isDisconnected() {
            configureVPN()
        }
    }

    @objc func connectButtonTapped() {
        VPNManager.shared.resetProperties()
        disableConnectButton()
        if statusLabel.text?.contains(TextsAsset.Status.off) ?? false {
            logger.logE(MainViewController.self, "User tapped to connect.")
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if isOnline {
                configureVPN()
            } else {
                enableConnectButton()
                displayInternetConnectionLostAlert()
            }
        } else {
            logger.logD(self, "User tapped to disconnect.")
            connectionStateViewModel.disconnect()
        }
    }

    @objc func enableConnectButton() {
        self.connectButton.isUserInteractionEnabled = true
    }

    @objc func expandButtonTapped() {
        if self.expandButton.tag == 0 {
            locationManagerViewModel.requestLocationPermission {
                self.showAutoSecureViews()
            }
        } else {
            self.hideAutoSecureViews()
            WifiManager.shared.configure()
            guard let result = WifiManager.shared.getConnectedNetwork() else { return }
            let nextProtocol = ConnectionManager.shared.getNextProtocol()
            VPNManager.shared.getVPNConnectionInfo { [self] info in
                if info != nil && info?.status == .connected && (nextProtocol.protocolName != result.preferredProtocol || nextProtocol.portName != result.preferredPort) {
                    configureVPN(bypassConnectingCheck: true)
                } else {
                    viewModel.refreshProtocolInfo()
                }
            }
        }
    }

    @objc func loadLatencyWhenReady() {
        guard let observer = self.latencyLoaderObserver else { return }
        if vpnManager.lastConnectionStatus == .invalid { return }
        NotificationCenter.default.removeObserver(observer)
        sessionManager.keepSessionUpdated()
        if appJustStarted && vpnManager.isDisconnected() {
            connectionStateViewModel.displayLocalIPAddress()
            loadLatencyValues(force: false, selectBestLocation: self.isBestLocationSelected(), connectToBestLocation: false)
        } else {
            reloadTableViews()
            hideSplashView()
            configureBestLocation(selectBestLocation: false, connectToBestLocation: false)
        }
        checkForOutsideIntent()
    }

    @objc func reachabilityChanged() {
        checkForInternetConnection()
        if !vpnManager.isConnected() {
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
        self.showNotificationsViewController()
    }

    @objc func upgradeButtonTapped() {
        logger.logD(self, "User tapped upgrade button.")
        showUpgradeView()
    }

    @objc func protocolPortLableTapped() {
        openConnectionChangeDialog()
    }
}

//
//  MainViewController+Bindings.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import UIKit

extension MainViewController {

    func bindLatencyViewModel() {
        latencyViewModel.latencyUpdatedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadTableViews()
            }
            .store(in: &cancellables)
    }

    func bindVPNConnectionsViewModel() {
        vpnConnectionViewModel.connectedState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                if [.connected, .disconnected].contains($0.state) {
                    self.viewModel.updateSSID()
                }
                self.updateRefreshControls()
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showNoConnectionAlertTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.displayInternetConnectionLostAlert()
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showPrivacyTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showPrivacyConfirmationPopup(willConnectOnAccepting: true)
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showAuthFailureTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showAuthFailurePopup()
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showUpgradeRequiredTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showUpgradeView()
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showConnectionFailedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showConnectionFailed()
            }
            .store(in: &cancellables)

        viewModel.wifiNetwork.combineLatest(vpnConnectionViewModel.selectedProtoPort)
            .sink { [weak self] (network, protocolPort) in
                self?.refreshProtocol(from: network, with: protocolPort)
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.pushNotificationPermissionsTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.popupRouter?.routeTo(to: .pushNotifications, from: self)
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.siriShortcutTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.displaySiriShortcutPopup()
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.loadLatencyValuesSubject
            .sink { [weak self] in
                self?.loadLatencyValues(force: $0.force, connectToBestLocation: $0.connectToBestLocation)
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showPreferredProtocolView
            .sink { [weak self] protocolName in
                guard let self = self else { return }
                self.router?.routeTo(to: RouteID.protocolConnectionResult(protocolName: protocolName,
                                                                          viewType: .connected),
                                     from: self)
            }
            .store(in: &cancellables)
    }

    func bindViews() {
        connectButtonView.connectTriggerSubject
            .sink { [weak self] _ in
                self?.connectButtonTapped()
            }
            .store(in: &cancellables)

        wifiInfoView.wifiTriggerSubject
            .sink { [weak self] network in
                guard let self = self else { return }
                self.router?.routeTo(to: .network(with: network), from: self)
            }
            .store(in: &cancellables)

        wifiInfoView.unknownWifiTriggerSubject
            .sink { [weak self] in
                guard let self = self else { return }
                self.locationPermissionManager.requestLocationPermission()
            }
            .store(in: &cancellables)

        ipInfoView.actionFailedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] popuptype in
                guard let self = self else { return }
                self.popupRouter?.routeTo(to: .bridgeApi(type: popuptype), from: self)
            }
            .store(in: &cancellables)

        ipInfoView.animateFavoriteSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.animateBottomFavoriteButton()
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showFailedPinIpTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.popupRouter?.routeTo(to: .bridgeApi(type: .pinIp), from: self)
            }
            .store(in: &cancellables)
    }

    func bindMainViewModel() {
        viewModel.isDarkMode.receive(on: DispatchQueue.main).sink { [weak self] in
            self?.updateLayoutForTheme(isDarkMode: $0)
        }.store(in: &cancellables)

        viewModel.sessionModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionModel in
                guard let self = self else { return }
                self.updateUIForSession(session: sessionModel)
            }
            .store(in: &cancellables)

        viewModel.promoPayload
            .compactMap { $0 }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] payload in
                guard let self = self else { return }
                self.logger.logD("MainViewController", "Showing upgrade view with payload: \(payload.description)")
                self.popupRouter?.routeTo(to: RouteID.upgrade(promoCode: payload.promoCode, pcpID: payload.pcpid), from: self)
            }
            .store(in: &cancellables)

        viewModel.notices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkForUnreadNotifications()
            }
            .store(in: &cancellables)

        viewModel.showNetworkSecurityTrigger
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    self.locationPermissionManager.requestLocationPermission()
                    await self.locationPermissionManager.waitForPermission()
                    self.popupRouter?.routeTo(to: .networkSecurity, from: self)
                }
            }.store(in: &cancellables)

        viewModel.showNotificationsTrigger
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                self.showNotificationsViewController()
            }.store(in: &cancellables)

        viewModel.showNotificationsTrigger
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                self.clearScrollHappened()
                self.checkAndShowShareDialogIfNeed()
            }.store(in: &cancellables)

        viewModel.showUpdateAvailableTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                guard let self = self else { return }
                self.showUpdateAvailableAlert(model: model)
            }.store(in: &cancellables)

        // Re-present the force-update alert whenever the app comes back to
        // the foreground while the force-update flag is still set. This handles
        // the case where the user backgrounds the app without going through
        // with the App Store update — the alert returns on resume.
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self,
                      let model = self.viewModel.pendingForceUpdate.value else { return }
                self.showUpdateAvailableAlert(model: model)
            }.store(in: &cancellables)

        vpnConnectionViewModel.reloadLocationsTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                guard let self = self else { return }
                if id.starts(with: "static") {
                    self.loadStaticIPs()
                } else if id.starts(with: "custom") {
                    self.loadCustomConfigs()
                } else {
                    self.loadServerList()
                }
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.reviewRequestTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.displayReviewConfirmationAlert()
            }
            .store(in: &cancellables)

        viewModel.showProtocolSwitchTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                // Disconnect VPN for clean state during countdown while preserving protocol failover sequence
                self.router?.routeTo(to: RouteID.protocolSwitch(type: .failure, error: nil), from: self)
            }
            .store(in: &cancellables)

        viewModel.showAllProtocolsFailedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                // Disconnect VPN to stop protocol cycling when all protocols have failed
                self.vpnConnectionViewModel.disableConnection()

                self.router?.routeTo(to: RouteID.protocolConnectionResult(protocolName: "", viewType: .fail), from: self)
            }
            .store(in: &cancellables)

        viewModel.showConnectionModeTriggeer
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                self.router?.routeTo(to: RouteID.protocolConnectionResult(protocolName: "", viewType: .manualFail), from: self)
            }.store(in: &cancellables)

        viewModel.disconnectConnectionTrigger
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                self.vpnConnectionViewModel.disableConnection()
            }.store(in: &cancellables)

        viewModel.showNoInternetBeforeFailoverTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                // Show no internet alert instead of protocol failover when no connectivity detected
                self.displayInternetConnectionLostAlert()
            }
            .store(in: &cancellables)

        viewModel.locationOrderBy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.expandedSections = self.locationsListTableView.expandedSections
                self.locationsListTableView.collapseExpandedSections()
                self.loadLocationsTable(locations: self.viewModel.locationsList.value)
            }
            .store(in: &cancellables)

        viewModel.locationsList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locations in
                guard let self = self else { return }
                self.loadLocationsTable(locations: locations)
            }
            .store(in: &cancellables)
        setNetworkSsid()
    }

    func bindActions() {
        preferencesTapAreaButton.tap
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true )
            .sink { [weak self] _ in
                self?.logoButtonTapped()
            }
            .store(in: &cancellables)
    }

    func bindCustomConfigPickerModel() {
        customConfigPickerViewModel.configureVPNTrigger
            .sink { [weak self] in
                self?.enableVPNConnection()
            }
            .store(in: &cancellables)
        customConfigPickerViewModel.disableVPNTrigger
            .sink { [weak self] in
                self?.disableVPNConnection()
            }
            .store(in: &cancellables)

        customConfigPickerViewModel.displayAllertTrigger
            .sink { [weak self] in
                switch $0 {
                case .connecting:
                    self?.displayConnectingAlert()
                case .disconnecting:
                    self?.displayDisconnectingAlert()
                }
            }
            .store(in: &cancellables)

        customConfigPickerViewModel.presentDocumentPickerTrigger
            .sink { [weak self] in
                self?.present($0, animated: true)
            }
            .store(in: &cancellables)

        customConfigPickerViewModel.showEditCustomConfigTrigger
            .sink { [weak self] in
                guard let self = self else { return }
                self.popupRouter?.routeTo(to: .enterCredentials(config: $0, isUpdating: true), from: self)
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.showEditCustomConfigTrigger
            .sink { [weak self] in
                guard let self = self else { return }
                self.popupRouter?.routeTo(to: .enterCredentials(config: $0, isUpdating: false), from: self)
            }
            .store(in: &cancellables)
    }

    func bindFavouriteListViewModel() {
        favNodesListViewModel.presentAlertTrigger
            .sink { [weak self] in
                switch $0 {
                case .connecting: self?.displayConnectingAlert()
                case .disconnecting: self?.displayDisconnectingAlert()
                }
            }
            .store(in: &cancellables)
        favNodesListViewModel.showMaintenanceLocationTrigger
            .sink { [weak self] _ in
                self?.showMaintenanceLocationView(isStaticIp: false)
            }
            .store(in: &cancellables)
        favNodesListViewModel.showUpgradeTrigger
            .sink { [weak self] _ in
                self?.showUpgradeView()
            }
            .store(in: &cancellables)
    }

    func bindStaticIPListViewModel() {
        staticIPListViewModel.presentLinkTrigger
            .sink { [weak self] in
                self?.openLink(url: $0, asSheet: true)
            }
            .store(in: &cancellables)
        staticIPListViewModel.presentAlertTrigger
            .sink { [weak self] in
                switch $0 {
                case .connecting:
                    self?.displayConnectingAlert()
                case .disconnecting:
                    self?.displayDisconnectingAlert()
                case .underMaintananence:
                    self?.showMaintenanceLocationView(isStaticIp: true)
                }
            }
            .store(in: &cancellables)
    }

    func bindServerListViewModel() {
        serverListViewModel.presentConnectingAlertTrigger
            .sink { [weak self] _ in
                self?.displayConnectingAlert()
            }
            .store(in: &cancellables)
        serverListViewModel.showMaintenanceLocationTrigger
            .sink { [weak self] _ in
                self?.showMaintenanceLocationView()
            }
            .store(in: &cancellables)
        serverListViewModel.showUpgradeTrigger
            .sink { [weak self] _ in
                self?.showUpgradeView()
            }
            .store(in: &cancellables)
        serverListViewModel.reloadTrigger
            .sink { [weak self] _ in
                self?.reloadTableViews()
            }
            .store(in: &cancellables)
    }

    func animateBottomFavoriteButton() {
        // Animate the bottom favorite button (green arrow heart)
        listSelectionView.animateFavoriteButton()
    }

}

//
//  MainViewController+Bindings.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import UIKit

extension MainViewController {
    func bindVPNConnectionsViewModel() {
        vpnConnectionViewModel.connectedState.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.animateConnectedState(with: $0)
            if [.connected, .disconnected].contains($0.state) {
                self.viewModel.updateSSID()
            }
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showNoConnectionAlertTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            self?.displayInternetConnectionLostAlert()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showPrivacyTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            self?.showPrivacyConfirmationPopup(willConnectOnAccepting: true)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showAuthFailureTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            self?.showAuthFailurePopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showUpgradeRequiredTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            self?.showOutOfDataPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showConnectionFailedTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            self?.showConnectionFailed()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.selectedLocationUpdated
            .delay(for: .seconds(vpnConnectionViewModel.getSelectedCountryInfo().countryCode.isEmpty ? 2 : 0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSelectedLocationUI()
            }.store(in: &cancellables)

        viewModel.wifiNetwork.combineLatest(vpnConnectionViewModel.selectedProtoPort.asPublisher().replaceError(with: nil).eraseToAnyPublisher())
            .sink { [weak self] (network, protocolPort) in
                self?.refreshProtocol(from: network, with: protocolPort)
            }.store(in: &cancellables)

        vpnConnectionViewModel.pushNotificationPermissionsTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.popupRouter?.routeTo(to: .pushNotifications, from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.siriShortcutTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            self?.displaySiriShortcutPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.loadLatencyValuesSubject.subscribe(onNext: { [weak self] in
            self?.loadLatencyValues(force: $0.force, connectToBestLocation: $0.connectToBestLocation)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showPreferredProtocolView.subscribe(onNext: { [weak self] protocolName in
            guard let self = self else { return }
            self.router?.routeTo(to: RouteID.protocolConnectionResult(protocolName: protocolName,
                                                                      viewType: .connected),
                                 from: self)
        }).disposed(by: disposeBag)
    }

    func bindViews() {
        connectButtonView.connectTriggerSubject.subscribe { [weak self] _ in
            self?.connectButtonTapped()
        }.disposed(by: disposeBag)

        wifiInfoView.wifiTriggerSubject.subscribe { [weak self] network in
            guard let self = self else { return }
            self.router?.routeTo(to: .network(with: network), from: self)
        }.disposed(by: disposeBag)

        wifiInfoView.unknownWifiTriggerSubject
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.locationPermissionManager.requestLocationPermission()
            })
            .disposed(by: disposeBag)

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

        viewModel.promoPayload.distinctUntilChanged().subscribe(onNext: { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            self.logger.logD("MainViewController", "Showing upgrade view with payload: \(payload.description)")
            self.popupRouter?.routeTo(to: RouteID.upgrade(promoCode: payload.promoCode, pcpID: payload.pcpid), from: self)
        }).disposed(by: disposeBag)

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
                self.updateConnectedState()
            }.store(in: &cancellables)

        vpnConnectionViewModel.reloadLocationsTrigger.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] id in
            guard let self = self else { return }
            if id.starts(with: "static") {
                self.loadStaticIPs()
            } else if id.starts(with: "custom") {
                self.loadCustomConfigs()
            } else {
                self.loadServerList()
            }
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.reviewRequestTrigger
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.displayReviewConfirmationAlert()
             })
             .disposed(by: disposeBag)

        viewModel.showProtocolSwitchTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            // Disconnect VPN for clean state during countdown while preserving protocol failover sequence
            self.router?.routeTo(to: RouteID.protocolSwitch(type: .failure, error: nil), from: self)
        }).disposed(by: disposeBag)

        viewModel.showAllProtocolsFailedTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            // Disconnect VPN to stop protocol cycling when all protocols have failed
            self.vpnConnectionViewModel.disableConnection()

            self.router?.routeTo(to: RouteID.protocolConnectionResult(protocolName: "", viewType: .fail), from: self)
        }).disposed(by: disposeBag)

        viewModel.showConnectionModeTriggeer
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                self.router?.routeTo(to: RouteID.protocolConnectionResult(protocolName: "", viewType: .manualFail), from: self)
            }.store(in: &cancellables)

        viewModel.showNoInternetBeforeFailoverTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            // Show no internet alert instead of protocol failover when no connectivity detected
            self.displayInternetConnectionLostAlert()
        }).disposed(by: disposeBag)

        viewModel.bestLocationUpdated
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                guard let self = self else { return }
                if let bestLocation = vpnConnectionViewModel.getBestLocation() {
                    serverListTableViewDataSource.bestLocation = bestLocation
                }
            }.store(in: &cancellables)

        setNetworkSsid()
    }

    func bindActions() {
        preferencesTapAreaButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance).bind { [weak self] in
            self?.logoButtonTapped()
        }.disposed(by: disposeBag)
    }

    func bindCustomConfigPickerModel() {
        customConfigPickerViewModel.configureVPNTrigger.subscribe(onNext: { [weak self] in
            self?.enableVPNConnection()
        }).disposed(by: disposeBag)
        customConfigPickerViewModel.disableVPNTrigger.subscribe(onNext: { [weak self] in
            self?.disableVPNConnection()
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.displayAllertTrigger.subscribe(onNext: { [weak self] in
            switch $0 {
            case .connecting:
                self?.displayConnectingAlert()
            case .disconnecting:
                self?.displayDisconnectingAlert()
            }
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.presentDocumentPickerTrigger.subscribe(onNext: { [weak self] in
            self?.present($0, animated: true)
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.showEditCustomConfigTrigger.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.popupRouter?.routeTo(to: .enterCredentials(config: $0, isUpdating: true), from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showEditCustomConfigTrigger.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.popupRouter?.routeTo(to: .enterCredentials(config: $0, isUpdating: false), from: self)
        }).disposed(by: disposeBag)
    }

    func bindFavouriteListViewModel() {
        favNodesListViewModel.presentAlertTrigger.subscribe { [weak self] in
            switch $0 {
            case .connecting: self?.displayConnectingAlert()
            case .disconnecting: self?.displayDisconnectingAlert()
            }
        }.disposed(by: disposeBag)
        favNodesListViewModel.showUpgradeTrigger.subscribe { [weak self] _ in
            self?.showUpgradeView()
        }.disposed(by: disposeBag)
    }

    func bindStaticIPListViewModel() {
        staticIPListViewModel.presentLinkTrigger.subscribe { [weak self] in
            self?.openLink(url: $0)
        }.disposed(by: disposeBag)
        staticIPListViewModel.presentAlertTrigger.subscribe { [weak self] in
            switch $0 {
            case .connecting:
                self?.displayConnectingAlert()
            case .disconnecting:
                self?.displayDisconnectingAlert()
            case .underMaintananence:
                self?.showMaintenanceLocationView(isStaticIp: true)
            }
        }.disposed(by: disposeBag)
    }

    func bindServerListViewModel() {
        serverListViewModel.presentConnectingAlertTrigger.subscribe { [weak self] _ in
            self?.displayConnectingAlert()
        }.disposed(by: disposeBag)
        serverListViewModel.showMaintenanceLocationTrigger.subscribe { [weak self] _ in
            self?.showMaintenanceLocationView()
        }.disposed(by: disposeBag)
        serverListViewModel.showUpgradeTrigger.subscribe { [weak self] _ in
            self?.showUpgradeView()
        }.disposed(by: disposeBag)
        serverListViewModel.reloadTrigger.subscribe { [weak self] _ in
            self?.reloadTableViews()
        }.disposed(by: disposeBag)
    }

    func animateBottomFavoriteButton() {
        // Animate the bottom favorite button (green arrow heart)
        listSelectionView.animateFavoriteButton()
    }

}

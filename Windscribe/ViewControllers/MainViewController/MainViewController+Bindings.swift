//
//  MainViewController+Bindings.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

extension MainViewController {
    func bindVPNConnectionsViewModel() {
        vpnConnectionViewModel.connectedState.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.animateConnectedState(with: $0)
            if [.connected, .disconnected].contains($0.state) {
                self.viewModel.updateSSID()
            }
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showNoConnectionAlertTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.displayInternetConnectionLostAlert()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.trustedNetworkPopupTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.router?.routeTo(to: .trustedNetwork, from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showPrivacyTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showPrivacyConfirmationPopup(willConnectOnAccepting: true)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showAuthFailureTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showAuthFailurePopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showUpgradeRequiredTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showOutOfDataPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showConnectionFailedTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showConnectionFailed()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.selectedLocationUpdatedSubject
            .delaySubscription(RxTimeInterval.seconds(vpnConnectionViewModel.getSelectedCountryInfo().countryCode.isEmpty ? 2 : 0), scheduler: MainScheduler.instance)
            .subscribe(onNext: {
                self.updateSelectedLocationUI()
            }).disposed(by: disposeBag)

        Observable.combineLatest(viewModel.wifiNetwork,
                                 vpnConnectionViewModel.selectedProtoPort).bind { (network, protocolPort) in
            self.refreshProtocol(from: network, with: protocolPort)
        }.disposed(by: disposeBag)

        vpnConnectionViewModel.showAutoModeScreenTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            guard let viewControllers = self.navigationController?.viewControllers,
                  !viewControllers.contains(where: { $0 is ProtocolSetPreferredViewController }),
                  !viewControllers.contains(where: { $0 is ProtocolSwitchViewController })
            else { return }

            self.router?.routeTo(to: RouteID.protocolSwitchVC(delegate: self.protocolSwitchViewModel, type: .failure), from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.openNetworkHateUsDialogTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.router?.routeTo(to: RouteID.protocolSetPreferred(type: .fail, delegate: self.protocolSwitchViewModel), from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.pushNotificationPermissionsTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.popupRouter?.routeTo(to: .pushNotifications, from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.siriShortcutTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.displaySiriShortcutPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.requestLocationTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.locationManagerViewModel.requestLocationPermission {
                self.router?.routeTo(to: RouteID.protocolSetPreferred(type: .connected, delegate: nil), from: self)
            }
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.loadLatencyValuesSubject.subscribe(onNext: {
            self.loadLatencyValues(force: $0.force, connectToBestLocation: $0.connectToBestLocation)
        }).disposed(by: disposeBag)
    }

    func bindViews() {
        connectButtonView.connectTriggerSubject.subscribe { _ in
            self.connectButtonTapped()
        }.disposed(by: disposeBag)

        wifiInfoView.wifiTriggerSubject.subscribe { network in
            self.router?.routeTo(to: .network(with: network), from: self)
        }.disposed(by: disposeBag)

        wifiInfoView.unknownWifiTriggerSubject.subscribe { _ in
            self.locationManagerViewModel.requestLocationPermission {
                self.viewModel.updateSSID()
            }
        }.disposed(by: disposeBag)
    }

    func bindMainViewModel() {
        viewModel.isDarkMode.subscribe(onNext: {
            self.updateLayoutForTheme(isDarkMode: $0)
        }).disposed(by: disposeBag)
        viewModel.session.subscribe(onNext: {
            self.updateUIForSession(session: $0)
        }).disposed(by: disposeBag)

        viewModel.promoPayload.distinctUntilChanged().subscribe(onNext: { payload in
            guard let payload = payload else { return }
            self.logger.logD(self, "Showing upgrade view with payload: \(payload.description)")
            self.popupRouter?.routeTo(to: RouteID.upgrade(promoCode: payload.promoCode, pcpID: payload.pcpid), from: self)
        }).disposed(by: disposeBag)

        viewModel.notices.subscribe(onNext: { _ in
            self.checkForUnreadNotifications()
        }, onError: { error in
            self.logger.logE(self, "Realm notifications error \(error.localizedDescription)")
        }).disposed(by: disposeBag)

        viewModel.showNetworkSecurityTrigger.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.locationManagerViewModel.requestLocationPermission {
                self.popupRouter?.routeTo(to: .networkSecurity, from: self)
            }
        }).disposed(by: disposeBag)

        viewModel.showNotificationsTrigger.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showNotificationsViewController()
        }).disposed(by: disposeBag)

        viewModel.becameActiveTrigger.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.clearScrollHappened()
            self.checkAndShowShareDialogIfNeed()
            self.updateConnectedState()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.reloadLocationsTrigger.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {  id in
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

        setNetworkSsid()
    }

    func bindActions() {
        preferencesTapAreaButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance).bind {
            self.logoButtonTapped()
        }.disposed(by: disposeBag)
    }

    func bindCustomConfigPickerModel() {
        customConfigPickerViewModel.configureVPNTrigger.subscribe(onNext: {
            self.enableVPNConnection()
        }).disposed(by: disposeBag)
        customConfigPickerViewModel.disableVPNTrigger.subscribe(onNext: {
            self.disableVPNConnection()
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.displayAllertTrigger.subscribe(onNext: {
            switch $0 {
            case .connecting:
                self.displayConnectingAlert()
            case .disconnecting:
                self.displayDisconnectingAlert()
            }
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.presentDocumentPickerTrigger.subscribe(onNext: {
            self.present($0, animated: true)
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.showEditCustomConfigTrigger.subscribe(onNext: {
            self.popupRouter?.routeTo(to: .enterCredentials(config: $0, isUpdating: true), from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showEditCustomConfigTrigger.subscribe(onNext: {
            self.popupRouter?.routeTo(to: .enterCredentials(config: $0, isUpdating: false), from: self)
        }).disposed(by: disposeBag)
    }

    func bindFavouriteListViewModel() {
        favNodesListViewModel.presentAlertTrigger.subscribe {
            switch $0 {
            case .connecting: self.displayConnectingAlert()
            case .disconnecting: self.displayDisconnectingAlert()
            }
        }.disposed(by: disposeBag)
        favNodesListViewModel.showUpgradeTrigger.subscribe { _ in
            self.showUpgradeView()
        }.disposed(by: disposeBag)
    }

    func bindStaticIPListViewModel() {
        staticIPListViewModel.presentLinkTrigger.subscribe {
            self.openLink(url: $0)
        }.disposed(by: disposeBag)
        staticIPListViewModel.presentAlertTrigger.subscribe {
            switch $0 {
            case .connecting:
                self.displayConnectingAlert()
            case .disconnecting:
                self.displayDisconnectingAlert()
            case .underMaintananence:
                self.showMaintenanceLocationView(isStaticIp: true)
            }
        }.disposed(by: disposeBag)
    }

    func bindServerListViewModel() {
        serverListViewModel.presentConnectingAlertTrigger.subscribe { _ in
            self.displayConnectingAlert()
        }.disposed(by: disposeBag)
        serverListViewModel.showMaintenanceLocationTrigger.subscribe { _ in
            self.showMaintenanceLocationView()
        }.disposed(by: disposeBag)
        serverListViewModel.showUpgradeTrigger.subscribe { _ in
            self.showUpgradeView()
        }.disposed(by: disposeBag)
        serverListViewModel.reloadTrigger.subscribe { _ in
            self.reloadTableViews()
        }.disposed(by: disposeBag)
    }

    func bindProtocolSwitchViewModel() {
        protocolSwitchViewModel.disableVPNTrigger.subscribe { _ in
            self.disableVPNConnection()
        }.disposed(by: disposeBag)
    }
}

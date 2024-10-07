//
//  MainViewController+LifeCycle.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import RxSwift
import Swinject

extension MainViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Main view loaded. Preparing layout.")
        loadLastConnected()
        addViews()
        renderBlurSpacedLabel()
        addGetMoreDataViews()
        addAutoModeSelectorViews()
        addAutoLayoutConstraintsForAutoModeSelectorViews()
        addAutolayoutConstraintsForGetMoreDataViews()
        addSearchViews()
        addCardHeaderView()
        displayLeftDataInformation()
        showSplashView()
        showPrivacyConfirmationPopup()
        // UserPreferencesManager.shared.listenForUserPreferencesChange()
        WifiManager.shared.saveCurrentWifiNetworks()
        loadPortMap()
        loadServerList()
        loadFavNodes()
        loadStaticIPs()
        loadCustomConfigs()
        loadLastConnection()
        loadNotifications()
        sessionManager.setSessionTimer()
        sessionManager.listenForSessionChanges()
        setupIntentsForSiri()
        configureNotificationListeners()
        // self.configureBestLocation(selectBestLocation: true, connectToBestLocation: false)
        self.loadLatencyWhenReady()
        checkForNewNotifications()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        checkForVPNActivation()
        updateServerConfigs()
        bindViewModels()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        locationManagerViewModel.shouldPresentLocationPopUp.subscribe {
            self.router?.routeTo(to: RouteID.locationPermission(delegate: self.locationManagerViewModel, denied: $0),
                                from: self)
        }.disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        connectionStateViewModel.becameActive()
        setNetworkSsid()
        checkForInternetConnection()
        hideAutoSecureViews()
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        restartServerRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchLocationsView.viewModel.dismiss()
    }

    func handleShortcutLaunch() {
        let shortcut = (UIApplication.shared.delegate as? AppDelegate)?.shortcutType ?? .none
        (UIApplication.shared.delegate as? AppDelegate)?.shortcutType = ShortcutType.none
        if shortcut == .networkSecurity {
            locationManagerViewModel.requestLocationPermission {
                self.openNetworkSecurity()
            }
        } else if shortcut == .notifications {
            showNotificationsViewController()
        }
    }

    private func bindViewModels() {
        bindMainViewModel()
 		bindCustomConfigPickerModel()
        bindConnectionStateViewModel()
        bindFavNodesListViewModel()
        bindStaticIPListViewModel()
        bindServerListViewModel()
        bindProtocolSwitchViewModel()
    }

    private func openNetworkSecurity() {
        let vc = Assembler.resolve(NetworkViewController.self)
        vc.modalTransitionStyle = .coverVertical
        navigationController?.pushViewController(vc, animated: true)
    }
}

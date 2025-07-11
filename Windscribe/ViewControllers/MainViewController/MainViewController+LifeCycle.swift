//
//  MainViewController+LifeCycle.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import CoreLocation
import Foundation
import RxSwift
import Swinject
import UIKit

extension MainViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Main view loaded. Preparing layout.")
        addViews()
        addCardHeaderView()
        addSearchViews()
        addAutoLayoutConstraints()
        showSplashView()
        checkPrivacyConfirmation()
        WifiManager.shared.saveCurrentWifiNetworks()
        loadPortMap()
        loadServerList()
        loadFavouriteList()
        loadStaticIPs()
        loadCustomConfigs()
        loadLastConnection()
        sessionManager.setSessionTimer()
        sessionManager.listenForSessionChanges()
        setupIntentsForSiri()
        configureNotificationListeners()
        loadLatencyWhenReady()
        overrideUserInterfaceStyle = .dark
        bindViewModels()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        locationPermissionManager.shouldShowPermissionUI
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] denied in
                guard let self else { return }
                self.router?.routeTo(
                    to: .locationPermission,
                    from: self
                )
            })
            .disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overrideUserInterfaceStyle = .dark
        viewModel.updateSSID()
        checkForInternetConnection()
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        restartServerRefreshControl()
        updateConnectedState()
        flagBackgroundView.redraw()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchLocationsView.viewModel.dismiss()
    }

    private func bindViewModels() {
        bindMainViewModel()
        bindCustomConfigPickerModel()
        bindVPNConnectionsViewModel()
        bindFavouriteListViewModel()
        bindStaticIPListViewModel()
        bindServerListViewModel()
        bindProtocolSwitchViewModel()
        bindActions()
        bindViews()
    }
}

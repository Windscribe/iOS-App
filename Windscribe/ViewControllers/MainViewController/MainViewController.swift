//
//  MainViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-29.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import CoreLocation
import ExpyTableView
import MobileCoreServices
import NetworkExtension
import RealmSwift
import RxSwift
import SafariServices
import StoreKit
import Swinject
import UIKit
import WidgetKit
import Combine

class MainViewController: WSUIViewController, UIGestureRecognizerDelegate {
    var preferencesTapAreaButton: LargeTapAreaImageButton!
    var notificationsTapAreaButton: UIButton!
    var logoStackView: UIStackView!
    var logoIcon: ImageButton!
    var proIcon: ImageButton!
    var notificationDot: UIButton!

    // MARK: background views
    var flagBackgroundView: FlagsBackgroundView!

    // MARK: table views
    var scrollView: WSScrollView!
    var favTableViewRefreshControl, staticIpTableViewRefreshControl, customConfigsTableViewRefreshControl: WSRefreshControl!
    var serverListTableView: PlainExpyTableView!
    var favTableView, staticIpTableView, customConfigTableView: PlainTableView!
    var staticIPTableViewFooterView: StaticIPListFooterView!
    var customConfigTableViewFooterView: CustomConfigListFooterView!
    var freeAccountViewFooterView: FreeAccountFooterView!

    var serverHeaderView: ServerInfoView!

    var listSelectionView: ListSelectionView!
    // search
    var searchLocationsView: SearchLocationsView!

    var sortedServerList: [ServerSection]?

    // MARK: connection views
    var connectButtonView: ConnectButtonView!
    var connectionStateInfoView: ConnectionStateInfoView!
    var spacer: UIView!
    var locationNameView: LocationNameView!
    var ipInfoView: IPInfoView!

    // MARK: Wifi Info views
    var wifiInfoView: WifiInfoView!

    // MARK: datasources
    var serverListTableViewDataSource: ServerListTableViewDataSource!
    var favNodesListTableViewDataSource: FavouriteListTableViewDataSource!
    var staticIPListTableViewDataSource: StaticIPListTableViewDataSource!
    var customConfigListTableViewDataSource: CustomConfigListTableViewDataSource!

    // MARK: properties

    var appJustStarted = false
    var userJustLoggedIn = false
    var didShowBannedProfilePopup = false
    var didShowOutOfDataPopup = false
    var didShowProPlanExpiredPopup = false
    var isLoadingLatencyValues = false
    var isRefreshing = false
    var internetConnectionLost = false
    var selectedNextProtocol: String?
    var didCheckForGhostAccount = false
    let userDefaults = UserDefaults.standard
    var isServerListLoading: Bool = false

    // MARK: Server section

    let serverSectionOpacity: Float = 1

    // MARK: shake for data trigger

    var shakeDetected = 0
    var firstShakeTimestamp = Date().timeIntervalSince1970
    var lastShakeTimestamp = Date().timeIntervalSince1970

    // MARK: realm tokens

    var serverListNotificationToken: NotificationToken?
    var favListNotificationToken: NotificationToken?
    var staticIPListNotificationToken: NotificationToken?
    var customConfigNotificationToken: NotificationToken?
    var sessionNotificationToken: NotificationToken?
    var bestLocationNotificationToken: NotificationToken?
    var notificationToken: NotificationToken?

    // MARK: Timers
    var autoModeSelectorViewTimer: Timer?
    var notificationTimer: Timer?
    var expandedSections: [Int: Bool]?
    var selectedHeaderViewTab: CardHeaderButtonType?
    var lastSelectedHeaderViewTab: CardHeaderButtonType?

    var router: HomeRouter?
    var accountRouter: AccountRouter?
    var popupRouter: PopupRouter?
    var pushNotificationManager: PushNotificationManager?

    // MARK: View Models
    var viewModel: MainViewModel!
    var vpnConnectionViewModel: ConnectionViewModelType!
    var customConfigPickerViewModel: CustomConfigPickerViewModelType!
    var favNodesListViewModel: FavouriteListViewModelType!
    var staticIPListViewModel: StaticIPListViewModelType!
    var serverListViewModel: ServerListViewModelType!
    var latencyViewModel: LatencyViewModel!

    // MARK: Managers
    var soundManager: SoundManaging!
    var locationPermissionManager: LocationPermissionManaging!
    var referAndShareManager: ReferAndShareManager!
    var logger: FileLogger!

    // MARK: constraints
    var listSelectionViewTopConstraint: NSLayoutConstraint!
    var listSelectionViewBottomConstraint: NSLayoutConstraint!

    var displayingNetwork: WifiNetworkModel? {
        return viewModel.wifiNetwork.value ?? WifiManager.shared.getConnectedNetwork()
    }

    lazy var serverListTableViewRefreshControl: WSRefreshControl = {
        let refreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        refreshControl.addTarget(self, action: #selector(serverRefreshControlValueChanged), for: .valueChanged)
        refreshControl.backView = RefreshControlBackView(frame: refreshControl.bounds)
        return refreshControl
    }()

    var customConfigRepository: CustomConfigRepository?

    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return false
    }

    func configureNotificationListeners() {
        NotificationCenter.default.publisher(for: Notifications.popoverDismissed)
            .sink { [weak self] _ in self?.popoverDismissed() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.serverListOrderPrefChanged)
            .sink { [weak self] _ in self?.reloadServerListOrder() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.reloadTableViews)
            .sink { [weak self] _ in self?.reloadTableViews() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.reachabilityChanged)
            .sink { [weak self] _ in self?.reachabilityChanged() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.checkForNotifications)
            .sink { [weak self] _ in self?.checkForUnreadNotifications() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.disconnectVPN)
            .sink { [weak self] _ in self?.disconnectVPNIntentReceived() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.connectToVPN)
            .sink { [weak self] _ in self?.connectVPNIntentReceived() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.showCustomConfigTab)
            .sink { [weak self] _ in self?.showCustomConfigTab() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.configureVPN)
            .sink { [weak self] _ in self?.enableVPNConnection() }
            .store(in: &cancellables)

        pushNotificationManager?.notification
            .compactMap { $0 }
            .sink { [weak self] in
                self?.pushNotificationReceived(payload: $0)
            }
            .store(in: &cancellables)

        if let payload = pushNotificationManager?.notification.value {
            if payload.type == "promo" {
                launchPromoView(payload: payload)
            }
        }
    }

    func launchPromoView(payload: PushNotificationPayload) {
        router?.routeTo(to: RouteID.upgrade(promoCode: payload.promoCode!, pcpID: payload.pcpid), from: self)
    }

    func pushNotificationReceived(payload: PushNotificationPayload) {
        if payload.type == "promo" {
            logger.logD("MainViewController", "Push notification type was promo now launching promo view. \(payload)")

            launchPromoView(payload: payload)
        }
    }

    func checkForInternetConnection() {
        guard vpnConnectionViewModel.isConnected() else { return }
        let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
        if !isOnline {
            logger.logI("MainViewController", "No internet connection available.")
            internetConnectionLost = true
            vpnConnectionViewModel.disableConnection()
        }
    }

    func showNotificationsViewController() {
        popupRouter?.routeTo(to: RouteID.newsFeedPopup, from: self)
    }

    func checkPrivacyConfirmation() {
        if !viewModel.isPrivacyPopupAccepted() {
            showPrivacyConfirmationPopup()
        }
    }

    func showPrivacyConfirmationPopup(willConnectOnAccepting: Bool = false) {
        if willConnectOnAccepting {
            // Observe privacy acceptance through the state manager
            vpnConnectionViewModel.checkForPrivacyConsent()
        }

        popupRouter?.routeTo(to: .privacyView, from: self)
    }

    func showUpgradeView() {
        accountRouter?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: self)
    }

    func showMaintenanceLocationView(isStaticIp: Bool = false) {
        popupRouter?.routeTo(to: .maintenanceLocation(isStaticIp: isStaticIp), from: self)
    }

    func configureBestLocation(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        if let bestLocation = vpnConnectionViewModel.getBestLocation() {
            let locationId = "\(bestLocation.groupId)"
            logger.logD("MainViewController", "Configuring best location.")
            if selectBestLocation || noSelectedNodeToConnect() {
                vpnConnectionViewModel.selectBestLocation(with: locationId)
            }
            if connectToBestLocation {
                logger.logD("MainViewController", "Forcing to connect to best location.")
                enableVPNConnection()
            }
            guard let displayingGroup = (try? self.viewModel.serverList.value())?
                .flatMap({ $0.groups }).filter({ $0.id == bestLocation.groupId }).first else { return }
            let isGroupProOnly = displayingGroup.premiumOnly

            if let isUserPro = viewModel.sessionModel.value?.isPremium,
               vpnConnectionViewModel.isDisconnected(),
               isGroupProOnly,
               !isUserPro {
                vpnConnectionViewModel.selectBestLocation(with: locationId)
            }
        }
    }

    func noSelectedNodeToConnect() -> Bool {
        return vpnConnectionViewModel.getSelectedCountryCode() == ""
    }

    func clearScrollHappened() {
        serverListTableViewDataSource.scrollHappened = false
        favNodesListTableViewDataSource.scrollHappened = false
        customConfigListTableViewDataSource.scrollHappened = false
        staticIPListTableViewDataSource.scrollHappened = false
    }

    func reloadServerList() {
        let results = (try? viewModel.serverList.value()) ?? []
        if results.count == 0 { return }

        if viewModel.checkAccountWasDowngraded(for: results) {
            if vpnConnectionViewModel.isDisconnected() {
                loadLatencyValues()
            } else {
                vpnConnectionViewModel.updateLoadLatencyValuesOnDisconnect(with: true)
            }
        }
        if isAnyRefreshControlIsRefreshing() {
            loadLatencyValues()
        }
        vpnConnectionViewModel.checkForForceDisconnect()
    }

    func reloadCustomConfigs() {
        guard let results = try? viewModel.customConfigs.value() else { return }
        var customConfigModels = [CustomConfigModel]()
        for result in results {
            customConfigModels.append(result.getModel())
        }

        customConfigListTableViewDataSource.updateCustomConfigList(with: customConfigModels)
    }

    func tableViewScrolled(toTop: Bool) {
    }

    override func setupLocalized() {
        viewModel.updateSSID()
    }

    func openConnectionChangeDialog() {
        router?.routeTo(to: RouteID.protocolSwitch(type: .change, error: nil), from: self)
    }

    deinit {
        print("MainViewController deinit called")
    }
}

enum ShortcutType {
    case networkSecurity
    case notifications
    case none
}

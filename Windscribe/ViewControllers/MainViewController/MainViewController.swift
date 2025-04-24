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

class MainViewController: WSUIViewController, UIGestureRecognizerDelegate {
    var preferencesTapAreaButton: LargeTapAreaImageButton!
    var logoIcon: ImageButton!
    var notificationDot: UIButton!

    // MARK: background views
    var flagBackgroundView: FlagsBackgroundView!

    // MARK: table views
    var scrollView: WScrollView!
    var favTableViewRefreshControl, staticIpTableViewRefreshControl, customConfigsTableViewRefreshControl: WSRefreshControl!
    var serverListTableView: PlainExpyTableView!
    var favTableView, staticIpTableView, customConfigTableView: PlainTableView!
    var staticIPTableViewFooterView: StaticIPListFooterView!
    var customConfigTableViewFooterView: CustomConfigListFooterView!
    var freeAccountViewFooterView: FreeAccountFooterView!

    var serverHeaderView: ServerInfoView!

    var serverHeaderView: ServerInfoView!

    var listSelectionView: ListSelectionView!
    // search
    var searchLocationsView: SearchLocationsView!

    var sortedServerList: [ServerSection]?

    // MARK: connection views
    var connectButtonView: ConnectButtonView!
    var connectionStateInfoView: ConnectionStateInfoView!
    var spacer: UIView!
    var connectedCityLabel, connectedServerLabel: UILabel!
    var ipInfoView: IPInfoView!

    // MARK: Wifi Info views
    var wifiInfoView: WifiInfoView!

    // MARK: datasources
    var serverListTableViewDataSource: ServerListTableViewDataSource?
    var favNodesListTableViewDataSource: FavNodesListTableViewDataSource?
    var staticIPListTableViewDataSource: StaticIPListTableViewDataSource?
    var customConfigListTableViewDataSource: CustomConfigListTableViewDataSource?

    // MARK: properties

    var appJustStarted = false
    var userJustLoggedIn = false
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
    var pushNotificationManager: PushNotificationManagerV2?

    // MARK: View Models
    var viewModel: MainViewModelType!
    var locationManagerViewModel: LocationManagingViewModelType!
    var vpnConnectionViewModel: ConnectionViewModelType!
    var customConfigPickerViewModel: CustomConfigPickerViewModelType!
    var favNodesListViewModel: FavNodesListViewModelType!
    var staticIPListViewModel: StaticIPListViewModelType!
    var serverListViewModel: ServerListViewModelType!
    var protocolSwitchViewModel: ProtocolSwitchDelegateViewModelType!
    var latencyViewModel: LatencyViewModel!

    var soundManager: SoundManaging!
    var customSoundPlaybackManager: CustomSoundPlaybackManaging!
    var logger: FileLogger!

    // MARK: constraints
    var listSelectionViewTopConstraint: NSLayoutConstraint!
    var listSelectionViewBottomConstraint: NSLayoutConstraint!

    var displayingNetwork: WifiNetwork? {
        return try? viewModel.wifiNetwork.value() ?? WifiManager.shared.getConnectedNetwork()
    }

    lazy var serverListTableViewRefreshControl: WSRefreshControl = {
        let refreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        refreshControl.addTarget(self, action: #selector(serverRefreshControlValueChanged), for: .valueChanged)
        refreshControl.backView = RefreshControlViewBack(frame: refreshControl.bounds)
        return refreshControl
    }()

    var customConfigRepository: CustomConfigRepository?

    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return false
    }

    func configureNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(popoverDismissed), name: Notifications.popoverDismissed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadServerListOrder), name: Notifications.serverListOrderPrefChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableViews), name: Notifications.reloadTableViews, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: Notifications.reachabilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkForUnreadNotifications), name: Notifications.checkForNotifications, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectVPNIntentReceived), name: Notifications.disconnectVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connectVPNIntentReceived), name: Notifications.connectToVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enableVPNConnection), name: Notifications.configureVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCustomConfigTab), name: Notifications.showCustomConfigTab, object: nil)
        pushNotificationManager?.notification.compactMap { $0 }.subscribe(onNext: { notification in
            self.pushNotificationReceived(payload: notification)
        }).disposed(by: disposeBag)
        if let payload = try? pushNotificationManager?.notification.value() {
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
            logger.logD(self, "Push notification type was promo now launching promo view. \(payload)")

            launchPromoView(payload: payload)
        }
    }

    func checkForInternetConnection() {
        guard vpnConnectionViewModel.isConnected() else { return }
        let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
        if !isOnline {
            logger.logI(MainViewController.self, "No internet connection available.")
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
        popupRouter?.routeTo(to: .privacyView(completionHandler: {
            if willConnectOnAccepting {
                self.enableVPNConnection()
            }
        }), from: self)
    }

    func showUpgradeView() {
        accountRouter?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: self)
    }

    func showMaintenanceLocationView(isStaticIp: Bool = false) {
        popupRouter?.routeTo(to: .maintenanceLocation(isStaticIp: isStaticIp), from: self)
    }

    func configureBestLocation(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        if let bestLocation = vpnConnectionViewModel.getBestLocation() {
            let locationId = "\(bestLocation.groupId ?? 0)"
            logger.logD(self, "Configuring best location.")
            serverListTableViewDataSource?.bestLocation = bestLocation
            if selectBestLocation || noSelectedNodeToConnect() {
                vpnConnectionViewModel.selectBestLocation(with: locationId)
            }
            if connectToBestLocation {
                logger.logD(self, "Forcing to connect to best location.")
                enableVPNConnection()
            }
            guard let displayingGroup = (try? self.viewModel.serverList.value())?
                .flatMap({ $0.groups ?? [] }).filter({ $0.id == bestLocation.groupId }).first else { return }
            let isGroupProOnly = displayingGroup.premiumOnly ?? false
            if let isUserPro = try? viewModel.session.value()?.isPremium,
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

    func showOutOfDataPopup() {
        logger.logD(self, "Displaying Out Of Data Popup.")
        popupRouter?.routeTo(to: RouteID.outOfDataAccountPopup, from: self)
    }

    func showProPlanExpiredPopup() {
        DispatchQueue.main.async {
            self.popupRouter?.routeTo(to: RouteID.proPlanExpireddAccountPopup, from: self)
        }
    }

    func clearScrollHappened() {
        serverListTableViewDataSource?.scrollHappened = false
        favNodesListTableViewDataSource?.scrollHappened = false
        customConfigListTableViewDataSource?.scrollHappened = false
        staticIPListTableViewDataSource?.scrollHappened = false
    }

    func reloadServerList() {
        let results = (try? viewModel.serverList.value()) ?? []
        if results.count == 0 { return }

        if let oldSession = viewModel.oldSession,
           let newSession = sessionManager.session {
            let groups = results.compactMap { $0.groups }.flatMap { $0 }
            let nodes = groups.compactMap { $0.nodes }.flatMap { $0 }
            if oldSession.isPremium &&
                !newSession.isPremium &&
                !nodes.isEmpty {
                logger.logD(self, "Account downgrade detected.")
                if vpnConnectionViewModel.isDisconnected() {
                    loadLatencyValues()
                } else {
                    vpnConnectionViewModel.updateLoadLatencyValuesOnDisconnect(with: true)
                }
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
        customConfigListTableViewDataSource?.customConfigs = customConfigModels
        customConfigTableView.reloadData()
    }

    func tableViewScrolled(toTop: Bool) {
    }

    override func setupLocalized() {
        viewModel.updateSSID()
    }

    func openConnectionChangeDialog() {
        router?.routeTo(to: RouteID.protocolSwitchVC(delegate: protocolSwitchViewModel, type: .change), from: self)
    }
}

enum ShortcutType {
    case networkSecurity
    case notifications
    case none
}

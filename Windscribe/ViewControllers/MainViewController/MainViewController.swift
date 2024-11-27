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
    // MARK: navbar

    var topNavBarImageView: UIImageView!
    var preferencesTapAreaButton: LargeTapAreaImageButton!
    var logoIcon: ImageButton!
    var notificationDot: UIButton!

    // MARK: background views

    var topView, cardTopView, cardView: UIView!
    var backgroundView, flagBackgroundView: UIView!
    var flagBottomGradientView: UIImageView!
    var gradient,
        backgroundGradient,
        flagBottomGradient: CAGradientLayer!
    var flagView: UIImageView!

    // MARK: table views

    var scrollView: WScrollView!
    var serverListTableView, streamingTableView: PlainExpyTableView!
    var favTableViewRefreshControl, streamingTableViewRefreshControl, staticIpTableViewRefreshControl, customConfigsTableViewRefreshControl: WSRefreshControl!
    var favTableView, staticIpTableView, customConfigTableView: PlainTableView!
    var staticIPTableViewFooterView: StaticIPListFooterView!
    var customConfigTableViewFooterView: CustomConfigListFooterView!

    // header selector views
    var serverHeaderView, headerBottomBorderView, headerGradientView: UIView!

    var cardHeaderContainerView: CardHeaderContainerView!
    // search
    var searchLocationsView: SearchLocationsView!

    var sortedServerList: [ServerSection]?

    // MARK: connection views

    var connectButtonRingView: UIImageView!
    var connectButton: UIButton!
    var statusView, statusDivider, spacer: UIView!
    var statusImageView, connectivityTestImageView: UIImageView!
    var statusLabel, connectedCityLabel, connectedServerLabel: UILabel!
    var protocolLabel, portLabel: UILabel!
    var preferredProtocolBadge: UIImageView!
    var circumventCensorshipBadge: UIImageView!
    var changeProtocolArrow: UIImageView!
    var yourIPValueLabel, trustedNetworkValueLabel: BlurredLabel!
    var yourIPIcon, trustedNetworkIcon: UIImageView!
    var cardViewTopConstraint: NSLayoutConstraint!

    // MARK: auto-secure views

    var expandButton: UIButton!
    var autoSecureLabel: UILabel!
    var preferredProtocolLabel: UILabel!
    var trustNetworkSwitch: SwitchButton!
    var preferredProtocolSwitch: SwitchButton!
    var cellDivider1: UIView!
    var autoSecureInfoButton, preferredProtocolInfoButton: UIButton!
    var protocolSelectionLabel, portSelectionLabel: UILabel!
    var manualViewDivider1: UIView!
    var protocolDropdownButton: DropdownButton!
    var portDropdownButton: DropdownButton!

    // MARK: auto-mode selector views

    var autoModeSelectorView: UIView!
    var autoModeSelectorInfoIconView: UIImageView!
    var autoModeInfoLabel: UILabel!
    var autoModeSelectorCounterLabel: UILabel!
    var autoModeSelectorIkev2Button: UIButton!
    var autoModeSelectorUDPButton: UIButton!
    var autoModeSelectorTCPButton: UIButton!
    var autoModeSelectorOverlayView: UIView!

    // MARK: datasources

    var serverListTableViewDataSource: ServerListTableViewDataSource?
    var streamingTableViewDataSource: StreamingListTableViewDataSource?
    var favNodesListTableViewDataSource: FavNodesListTableViewDataSource?
    var staticIPListTableViewDataSource: StaticIPListTableViewDataSource?
    var customConfigListTableViewDataSource: CustomConfigListTableViewDataSource?

    // MARK: dynamic constraints

    var flagViewTopConstraint: NSLayoutConstraint!
    var preferredBadgeConstraints: [NSLayoutConstraint]!
    var circumventCensorshipBadgeConstraints: [NSLayoutConstraint]!
    var changeProtocolArrowConstraints: [NSLayoutConstraint]!

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

    weak var latencyLoaderObserver: NSObjectProtocol?
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
    var connectionStateViewModel: ConnectionStateViewModelType!
    var vpnConnectionViewModel: ConnectionViewModelType!
    var customConfigPickerViewModel: CustomConfigPickerViewModelType!
    var favNodesListViewModel: FavNodesListViewModelType!
    var staticIPListViewModel: StaticIPListViewModelType!
    var serverListViewModel: ServerListViewModelType!
    var protocolSwitchViewModel: ProtocolSwitchDelegateViewModelType!
    var latencyViewModel: LatencyViewModel!
    var rateViewModel: RateUsPopupModelType!
    var logger: FileLogger!

    var headerBottomBorderViewBottomConstraint: NSLayoutConstraint!

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

    func bindMainViewModel() {
        viewModel.isDarkMode.subscribe(onNext: {
            self.updateLayoutForTheme(isDarkMode: $0)
        }).disposed(by: disposeBag)
        viewModel.session.subscribe(onNext: {
            self.updateUIForSession(session: $0)
        }).disposed(by: disposeBag)

        viewModel.wifiNetwork.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            let protoPort =  try? self.vpnConnectionViewModel.selectedProtoPort.value()
            self.refreshProtocol(from: $0, with: protoPort)
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
        }).disposed(by: disposeBag)
    }

    func configureNotificationListeners() {
        if vpnConnectionViewModel.isDisconnected() {
            loadLatencyWhenReady()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(popoverDismissed), name: Notifications.popoverDismissed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadServerListOrder), name: Notifications.serverListOrderPrefChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableViews), name: Notifications.reloadTableViews, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configureBestLocationDefault), name: Notifications.configureBestLocation, object: nil)
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
            if willConnectOnAccepting { self.enableVPNConnection() }
        }), from: self)
    }

    func showUpgradeView() {
        accountRouter?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: self)
    }

    func showMaintenanceLocationView() {
        popupRouter?.routeTo(to: .maintenanceLocation, from: self)
    }

    // TODO: refactor vpn configs
    func configureBestLocation(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        viewModel.bestLocation.filter { $0?.isInvalidated == false }.bind(onNext: { bestLocation in
            guard let bestLocation = bestLocation, bestLocation.isInvalidated == false else { return }
            self.logger.logD(self, "Configuring best location.")
            self.serverListTableViewDataSource?.bestLocation = bestLocation.getBestLocationModel()
            if selectBestLocation || self.noSelectedNodeToConnect() {
                self.connectionStateViewModel.updateBestLocation(bestLocation: bestLocation)
            }
            if connectToBestLocation {
                self.logger.logD(self, "Forcing to connect to best location.")
                self.enableVPNConnection()
            }
            guard let displayingGroup = try? self.viewModel.serverList.value().flatMap({ $0.groups }).filter({ $0.id == bestLocation.groupId }).first else { return }
            let isGroupProOnly = displayingGroup.premiumOnly
            if let isUserPro = try? self.viewModel.session.value()?.isPremium,
               isGroupProOnly,
               !isUserPro {
                self.connectionStateViewModel.updateBestLocation(bestLocation: bestLocation)
            }
        }).disposed(by: disposeBag)
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
        streamingTableViewDataSource?.scrollHappened = false
        favNodesListTableViewDataSource?.scrollHappened = false
        customConfigListTableViewDataSource?.scrollHappened = false
        staticIPListTableViewDataSource?.scrollHappened = false
    }

    func reloadServerList() {
        let results = (try? viewModel.serverList.value()) ?? []
        if results.count == 0 { return }

        if let oldSession = viewModel.oldSession,
           let newSession = sessionManager.session {
            let groups = results.flatMap { $0.groups }
            let nodes = groups.flatMap { $0.nodes }
            if oldSession.isPremium &&
                !newSession.isPremium &&
                !nodes.isEmpty {
                logger.logD(self, "Account downgrade detected.")
                if vpnConnectionViewModel.isDisconnected() {
                    loadLatencyValues()
                } else {
                    connectionStateViewModel.updateLoadLatencyValuesOnDisconnect(with: true)
                }
            }
        }

        if isAnyRefreshControlIsRefreshing() {
            loadLatencyValues()
        }
        if vpnConnectionViewModel.isConnected() {
            vpnConnectionViewModel.enableConnection()
        }
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

    func showNoInternetConnection() {
        statusLabel.isHidden = true
        statusImageView.image = UIImage(named: ImagesAsset.noInternet)
        statusImageView.isHidden = false
        connectivityTestImageView.isHidden = true
    }

    func setConnectionLabelValuesForSelectedNode(selectedNode: SelectedNode) {
        DispatchQueue.main.async {
            self.showFlagAnimation(countryCode: selectedNode.countryCode, autoPicked: selectedNode.autoPicked || selectedNode.customConfig != nil)
            self.connectedServerLabel.text = selectedNode.nickName
            if selectedNode.cityName == Fields.Values.bestLocation {
                self.connectedCityLabel.text = TextsAsset.bestLocation
            } else {
                self.connectedCityLabel.text = selectedNode.cityName
            }
        }
    }

    func showFlagAnimation(countryCode: String, autoPicked: Bool = false) {
        DispatchQueue.main.async {
            if autoPicked {
                UIView.transition(with: self.flagView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                    self.flagView.image = UIImage(named: countryCode)
                }, completion: nil)
                return
            }
            if self.flagView.frame.height != 0 {
                self.flagViewTopConstraint.constant = self.flagView.frame.height + 10
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.flagView.image = UIImage(named: countryCode)
                    self.flagViewTopConstraint.constant = 0
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                })
            }
        }
    }

    func tableViewScrolled(toTop: Bool) {
        // serverRefreshControlValueChanged()
        hideHeaderGradient(hide: toTop)
    }

    override func setupLocalized() {
        displayLeftDataInformation()
        getMoreDataButton.setTitle(TextsAsset.getMoreData.uppercased(), for: .normal)
        setNetworkSsid()
        localizeAutoSecure()
    }

    func openConnectionChangeDialog() {
        router?.routeTo(to: RouteID.protocolSwitchVC(delegate: protocolSwitchViewModel, type: .change), from: self)
    }

    private func hideAutoModeSelectorView(connect: Bool = false) {
        showGetMoreDataViews()

        autoModeSelectorViewTimer?.invalidate()
        UIView.animate(withDuration: 1.0, animations: {
            self.autoModeSelectorView.frame = CGRect(x: 16, y: self.view.frame.maxY + 100, width: self.view.frame.width - 32, height: 44)
        }, completion: { _ in
            self.autoModeSelectorView.isHidden = true
            if connect {
                self.vpnConnectionViewModel.enableConnection()
            }
        })
    }
}

enum ShortcutType {
    case networkSecurity
    case notifications
    case none
}

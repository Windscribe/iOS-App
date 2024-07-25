//
//  ViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-29.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import UIKit
import RealmSwift
import NetworkExtension
import ExpyTableView
import SafariServices
import MobileCoreServices
import WidgetKit
import CoreLocation
import Swinject
import RxSwift

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
    let vpnManager = VPNManager.shared
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
    var connectivityTestTimer: Timer?
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
    var customConfigPickerViewModel: CustomConfigPickerViewModelType!
    var favNodesListViewModel: FavNodesListViewModelType!
    var staticIPListViewModel: StaticIPListViewModelType!
    var serverListViewModel: ServerListViewModelType!
    var protocolSwitchViewModel: ProtocolSwitchDelegateViewModelType!
    var latencyViewModel: LatencyViewModel!
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

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
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
            self.refreshProtocol(from: $0)
        }).disposed(by: disposeBag)
    }

    func checkForVPNActivation() {
        NEVPNManager.shared().loadFromPreferences(completionHandler: { error in
            if error == nil {
                if self.viewModel.isPrivacyPopupAccepted() &&
                    WifiManager.shared.getConnectedNetwork()?.SSID == TextsAsset.cellular &&
                    (!IKEv2VPNManager.shared.isConfigured() &&
                     !OpenVPNManager.shared.isConfigured() &&
                     !WireGuardVPNManager.shared.isConfigured()) {
                    IKEv2VPNManager.shared.configureDummy { [weak self] _,_ in
                        self?.setNetworkSsid()
                        self?.viewModel.refreshProtocolInfo()
                    }
                }
            }
        })
    }

    func configureForUnauthorizedVPNConfiguration() {
        IKEv2VPNManager.shared.neVPNManager.loadFromPreferences { [weak self] _ in
            guard let self = self else { return }
            let configuration = IKEv2VPNManager.shared.neVPNManager.protocolConfiguration?.username ?? OpenVPNManager.shared.providerManager?.protocolConfiguration?.username ?? WireGuardVPNManager.shared.providerManager?.protocolConfiguration?.username ?? ""
            if configuration == "" || self.userJustLoggedIn {
                self.connectionStateViewModel.displayLocalIPAddress(force: true)
                self.loadLatencyValues(force: true, selectBestLocation: true, connectToBestLocation: false)
            }
        }
    }

    func configureNotificationListeners() {
        OpenVPNManager.shared.setup { [weak self] in
            guard let self = self else { return }
            self.vpnManager.configureForConnectionState()
            self.configureForUnauthorizedVPNConfiguration()
            self.latencyLoaderObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NEVPNStatusDidChange,
                object: nil,
                queue: .main) { _ in
                    self.loadLatencyWhenReady()
                }
            if self.vpnManager.isDisconnected() && OpenVPNManager.shared.isConfigured() {
                self.loadLatencyWhenReady()
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadLastConnected), name: Notifications.loadLastConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.popoverDismissed), name: Notifications.popoverDismissed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadServerListOrder), name: Notifications.serverListOrderPrefChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableViews), name: Notifications.reloadTableViews, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.configureBestLocationDefault), name: Notifications.configureBestLocation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged), name: Notifications.reachabilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appEnteredForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.checkForUnreadNotifications), name: Notifications.checkForNotifications, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.disconnectVPNIntentReceived), name: Notifications.disconnectVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.connectVPNIntentReceived), name: Notifications.connectToVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.configureVPN), name: Notifications.configureVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showCustomConfigTab), name: Notifications.showCustomConfigTab, object: nil)
        pushNotificationManager?.notification.compactMap {$0}.subscribe(onNext: { notification in
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

    func isBestLocationSelected() -> Bool {
        return vpnManager.selectedNode?.cityName == Fields.Values.bestLocation
    }

    func checkForInternetConnection() {
        if VPNManager.shared.connectionStatus() != NEVPNStatus.connected {
            return
        }
        let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
        if !isOnline {
            logger.logE(MainViewController.self, "No internet connection available.")
            self.internetConnectionLost = true
            self.vpnManager.isOnDemandRetry = false
            vpnManager.disconnectActiveVPNConnection(setDisconnect: true)
        }
    }

    func showNotificationsViewController() {
        popupRouter?.routeTo(to: RouteID.newsFeedPopup, from: self)
    }

    func showPrivacyConfirmationPopup() {
        if !viewModel.isPrivacyPopupAccepted() {
            popupRouter?.routeTo(to: .privacyView, from: self)
        }
    }

    func showUpgradeView() {
        accountRouter?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: self)
    }

    func showMaintenanceLocationView() {
        popupRouter?.routeTo(to: .maintenanceLocation, from: self)
    }

    func showSetPreferredProtocolPopup() {
        if WifiManager.shared.getConnectedNetwork()?.preferredProtocolStatus == false && WifiManager.shared.getConnectedNetwork()?.status == false && WifiManager.shared.getConnectedNetwork()?.dontAskAgainForPreferredProtocol == false {
            popupRouter?.routeTo(to: .setPreferredProtocolPopup, from: self)
        }
    }

    func updateServerConfigs() {
        viewModel.updateServerConfig()
    }

    func configureBestLocation(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        viewModel.bestLocation.bind(onNext: { bestLocation in
            guard let bestLocation = bestLocation , bestLocation.isInvalidated == false else { return }
            self.logger.logD(self, "Configuring best location.")
            self.serverListTableViewDataSource?.bestLocation = bestLocation.getBestLocationModel()
            if selectBestLocation && self.vpnManager.isDisconnected() || self.noSelectedNodeToConnect() {
                self.vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode, dnsHostname: bestLocation.dnsHostname, hostname: bestLocation.hostname, serverAddress: bestLocation.ipAddress, nickName: bestLocation.nickName, cityName: bestLocation.cityName, autoPicked: true, groupId: bestLocation.groupId)
            }
            if connectToBestLocation {
                self.logger.logD(self, "Forcing to connect to best location.")
                self.configureVPN()
            }
            guard let displayingGroup = try? self.viewModel.serverList.value().flatMap({ $0.groups }).filter({ $0.id == bestLocation.groupId }).first else { return }
            let isGroupProOnly = displayingGroup.premiumOnly
            if let isUserPro = try? self.viewModel.session.value()?.isPremium {
                if (self.vpnManager.isConnected() == false) && (self.vpnManager.isConnecting() == false) && (self.vpnManager.isDisconnected() == true) && (self.vpnManager.isDisconnecting() == false) && isGroupProOnly && !isUserPro {
                    self.vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode, dnsHostname: bestLocation.dnsHostname, hostname: bestLocation.hostname, serverAddress: bestLocation.ipAddress, nickName: bestLocation.nickName, cityName: bestLocation.cityName, autoPicked: true, groupId: bestLocation.groupId)
                }
            }
        }).disposed(by: disposeBag )

    }

    func noSelectedNodeToConnect() -> Bool {
        return self.vpnManager.selectedNode == nil
    }

    func showOutOfDataPopup() {
        if vpnManager.isConnected() && !vpnManager.isCustomConfigSelected() {
            connectionStateViewModel.disconnect()
        }
        self.logger.logD(self, "Displaying Out Of Data Popup.")
        popupRouter?.routeTo(to: RouteID.outOfDataAccountPopup, from: self)
    }

    func showRateUsPopup() {
        let vc = RateUsPopupViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }

    func showProPlanExpiredPopup() {
        if vpnManager.isConnected() {
            connectionStateViewModel.disconnect()
        }
        DispatchQueue.main.async {
            self.popupRouter?.routeTo(to: RouteID.proPlanExpireddAccountPopup, from: self)
        }

    }

    func clearScrollHappened() {
        self.serverListTableViewDataSource?.scrollHappened = false
        self.streamingTableViewDataSource?.scrollHappened = false
        self.favNodesListTableViewDataSource?.scrollHappened = false
        self.customConfigListTableViewDataSource?.scrollHappened = false
        self.staticIPListTableViewDataSource?.scrollHappened = false
    }

    func reloadServerList() {
        let results = (try? self.viewModel.serverList.value()) ?? []
        if results.count == 0 { return }

        if let oldSession = self.viewModel.oldSession,
           let newSession = sessionManager.session {
            let groups = results.flatMap({ $0.groups })
            let nodes = groups.flatMap({ $0.nodes })
            if oldSession.isPremium &&
                !newSession.isPremium &&
                !nodes.isEmpty {
                self.logger.logD(self, "Account downgrade detected.")
                if self.vpnManager.isDisconnected() {
                    self.loadLatencyValues(selectBestLocation: true, connectToBestLocation: false)
                } else {
                    self.connectionStateViewModel.updateLoadLatencyValuesOnDisconnect(with: true)
                    self.vpnManager.resetProperties()
                    self.vpnManager.disconnectActiveVPNConnection(disableConnectIntent: true)
                }
            }
        }

        if self.isAnyRefreshControlIsRefreshing() {
            self.loadLatencyValues(selectBestLocation: self.isBestLocationSelected(), connectToBestLocation: false)
        }

        self.vpnManager.checkForForceDisconnect()
    }

    func reloadCustomConfigs() {
        guard let results = try? viewModel.customConfigs.value() else { return }
        var customConfigModels = [CustomConfigModel]()
        for result in results {
            customConfigModels.append(result.getModel())
        }
        self.customConfigListTableViewDataSource?.customConfigs = customConfigModels
        self.customConfigTableView.reloadData()
    }

    func sortServerListUsingUserPreferences(serverSections: [ServerSection]) -> [ServerSection] {
        var serverSectionsOrdered = [ServerSection]()
        guard let orderLocationsBy = try? viewModel.locationOrderBy.value() else { return serverSections}
        switch orderLocationsBy {
        case Fields.Values.geography:
            serverSectionsOrdered = serverSections
        case Fields.Values.alphabet:
            serverSectionsOrdered = serverSections.sorted { (serverSection1, serverSection2) -> Bool in
                guard let countryCode1 = serverSection1.server?.name, let countryCode2 = serverSection2.server?.name else { return false }
                return countryCode1 < countryCode2
            }
        case Fields.Values.latency:
            serverSectionsOrdered = serverSections.sorted { (serverSection1, serverSection2) -> Bool in
                guard let hostnamesFirst = serverSection1.server?.groups?.filter({$0.pingIp != ""}).map({$0.pingIp}), let hostnamesSecond = serverSection2.server?.groups?.filter({$0.pingIp != ""}).map({$0.pingIp}) else { return false }
                let firstNodeList = hostnamesFirst.map({viewModel.getLatency(ip: $0 ?? "")}).filter({ $0 != 0 })
                let secondNodeList = hostnamesSecond.map({viewModel.getLatency(ip: $0 ?? "")}).filter({ $0 != 0 }).filter({ $0 != 0 })
                let firstLatency = firstNodeList.reduce(0, { (result, value) -> Int in
                    return result + value
                })
                let secondLatency = secondNodeList.reduce(0, { (result, value) -> Int in
                    return result + value
                })
                if firstNodeList.count == 0 ||
                    secondNodeList.count == 0 ||
                    firstLatency == 0 ||
                    secondLatency == 0 {
                    return false
                }
                return (firstLatency / (firstNodeList.count)) < (secondLatency / (secondNodeList.count))
            }
        default:
            return serverSections
        }
        self.logger.logD(self, "Sorting server list by \(orderLocationsBy).")
        return serverSectionsOrdered
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
                self.flagViewTopConstraint.constant = self.flagView.frame.height+10
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

    func checkForOutsideIntent() {
        if vpnManager.connectWhenReady {
            vpnManager.connectWhenReady = false
            connectVPNIntentReceived()
            return
        }
        if vpnManager.disconnectWhenReady {
            vpnManager.disconnectWhenReady = false
            disconnectVPNIntentReceived()
            return
        }
    }

    func disconnectVPN(force: Bool = false) {
        vpnManager.isOnDemandRetry = false
        vpnManager.connectIntent = false
        vpnManager.userTappedToDisconnect = true
        hideAutoModeSelectorView(connect: false)
        vpnManager.disconnectAllVPNConnections(setDisconnect: true, force: force)
    }

    func disableConnectButton() {
        connectButton.isUserInteractionEnabled = false
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(enableConnectButton), userInfo: nil, repeats: false)
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
                self.vpnManager.connectUsingAutomaticMode()
                self.connectionStateViewModel.startConnecting()
            }
        })
    }
}

enum ShortcutType {
    case networkSecurity
    case notifications
    case none
}

//
//  MainViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import Swinject
import NetworkExtension

class MainViewController: PreferredFocusedViewController {
    @IBOutlet weak var settingsButton: SettingButton!
    @IBOutlet weak var notificationButton: NotificationButton!
    @IBOutlet weak var helpButton: HelpButton!
    @IBOutlet weak var flagView: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    var flagBackgroundView: UIView!
    var flagBottomGradientView: UIImageView!
    var gradient,
        backgroundGradient,
        flagBottomGradient: CAGradientLayer!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var ipIcon: UIImageView!
    @IBOutlet weak var portLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var protocolLabel: UILabel!
    @IBOutlet weak var connectedCityLabel: UILabel!
    @IBOutlet weak var connectedServerLabel: UILabel!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var connectionButtonRing: UIImageView!

    @IBOutlet weak var upgradeButton: UpgradeButton!
    @IBOutlet weak var bestLocationImage: UIImageView!
    @IBOutlet weak var firstServer: UIImageView!
    @IBOutlet weak var secondServer: UIImageView!
    @IBOutlet weak var thirdServer: UIImageView!
    @IBOutlet weak var locationsLabel: UILabel!
    @IBOutlet weak var nextViewButton: UIButton!

    // MARK: Properties
    var viewModel: MainViewModelType!
    var connectionStateViewModel: ConnectionStateViewModelType!
    var latencyViewModel: LatencyViewModel!
    var serverListViewModel: ServerListViewModelType!
    var favNodesListViewModel: FavNodesListViewModelType!
    var staticIPListViewModel: StaticIPListViewModelType!
    var router: HomeRouter!
    let disposeBag = DisposeBag()
    let vpnManager = VPNManager.shared
    var logger: FileLogger!
    var isFromServer: Bool = false
    var bestLocation: BestLocationModel?
    lazy var sessionManager = Assembler.resolve(SessionManagerV2.self)
    private lazy var languageManager: LanguageManagerV2 = {
        return Assembler.resolve(LanguageManagerV2.self)
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViews()
        setupSwipeDownGesture()
        loadLastConnection()
        loadLastConnected()
        sessionManager.setSessionTimer()
        sessionManager.listenForSessionChanges()
        self.refreshProtocol(from: try? viewModel.wifiNetwork.value())
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        connectionStateViewModel.becameActive()

    }

    @objc func appEnteredForeground() {
        sessionManager.keepSessionUpdated()
    }

    private func setupUI() {
        myPreferredFocusedView = connectionButton
        self.view.backgroundColor = UIColor.clear
        backgroundView.backgroundColor = UIColor.clear

        flagView.contentMode = .scaleAspectFill
        flagView.layer.opacity = 0.25
        gradient = CAGradientLayer()
        gradient.frame = flagView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.lightMidnight.cgColor]
        gradient.locations = [0, 0.65]
        flagView.layer.mask = gradient

        flagBackgroundView = UIView()
        flagBackgroundView.frame = flagView.bounds
        flagBackgroundView.backgroundColor = UIColor.lightMidnight
        backgroundGradient = CAGradientLayer()
        backgroundGradient.frame = flagBackgroundView.bounds
        backgroundGradient.colors = [UIColor.lightMidnight.cgColor, UIColor.clear.cgColor]
        backgroundGradient.locations = [0.0, 1.0]
        flagBackgroundView.layer.mask = backgroundGradient
        self.view.addSubview(flagBackgroundView)

        settingsButton.bringToFront()
        notificationButton.bringToFront()
        helpButton.bringToFront()
        connectionButton.bringToFront()

        flagBackgroundView.sendToBack()

        ipLabel.font = UIFont.bold(size: 25)
        dividerView.backgroundColor = .whiteWithOpacity(opacity: 0.24)
        protocolLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        protocolLabel.font = .bold(size: 35)
        portLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        portLabel.font = .bold(size: 35)
        statusLabel.layer.cornerRadius = statusLabel.frame.height/2
        statusLabel.clipsToBounds = true
        statusLabel.backgroundColor = .whiteWithOpacity(opacity: 0.24)
        statusLabel.font = .bold(size: 35)

        connectedCityLabel.font = .bold(size: 135)
        connectedServerLabel.font = .text(size: 120)
        connectionButton.layer.cornerRadius = connectionButton.frame.height/2
        connectionButton.clipsToBounds = true
        bestLocationImage.layer.cornerRadius = 10
        bestLocationImage.layer.masksToBounds = true
        bestLocationImage.layer.borderWidth = 5
        bestLocationImage.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor

        firstServer.layer.masksToBounds = false
        firstServer.layer.shadowColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        firstServer.layer.shadowOpacity = 1
        firstServer.layer.shadowOffset = CGSize(width: 10, height: 10)
        firstServer.layer.shadowRadius = 0.0

        secondServer.layer.masksToBounds = false
        secondServer.layer.shadowColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        secondServer.layer.shadowOpacity = 1
        secondServer.layer.shadowOffset = CGSize(width: 10, height: 10)
        secondServer.layer.shadowRadius = 0.0

        thirdServer.layer.masksToBounds = false
        thirdServer.layer.shadowColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        thirdServer.layer.shadowOpacity = 1
        thirdServer.layer.shadowOffset = CGSize(width: 10, height: 10)
        thirdServer.layer.shadowRadius = 0.0

        bestLocationImage.adjustsImageWhenAncestorFocused = true
        bestLocationImage.clipsToBounds = false

        locationsLabel.font = .bold(size: 35)
    }

    @IBAction func settingsPressed(_ sender: Any) {
        router.routeTo(to: RouteID.preferences, from: self)
    }

    @IBAction func notificationsClicked(_ sender: Any) {
        router.routeTo(to: RouteID.newsFeed, from: self)
    }

    @IBAction func helpClicked(_ sender: Any) {
        router.routeTo(to: RouteID.support, from: self)
    }

    @IBAction func upgradeButtonPressed(_ sender: Any) {
        router.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil, shouldBeRoot: false), from: self)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for press in presses {
            if press.type == .downArrow {
                if nextViewButton.isFocused {
                    myPreferredFocusedView = connectionButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                    router.routeTo(to: .serverList(bestLocation: self.bestLocation), from: self)
                }
            } else if press.type == .upArrow {
                if connectionButton.isFocused {
                    myPreferredFocusedView = notificationButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                }
            } else if press.type == .rightArrow {
                if preferredFocusedView == notificationButton {
                    myPreferredFocusedView = helpButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                } else if preferredFocusedView == settingsButton || UIScreen.main.focusedView == settingsButton {
                    myPreferredFocusedView = notificationButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                } else if preferredFocusedView == helpButton {
                    myPreferredFocusedView = upgradeButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                }

            } else if press.type == .leftArrow {
                if preferredFocusedView == notificationButton {
                    myPreferredFocusedView = settingsButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                } else if preferredFocusedView == helpButton {
                    myPreferredFocusedView = notificationButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                } else if preferredFocusedView == upgradeButton {
                    myPreferredFocusedView = helpButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                }
            }
        }
    }

    private func setupSwipeDownGesture() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        let swipeleft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
        swipeleft.direction = .left
        view.addGestureRecognizer(swipeleft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipeDown(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if connectionButton.isFocused {
                myPreferredFocusedView = connectionButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
                DispatchQueue.main.async {
                    self.router.routeTo(to: .serverList(bestLocation: self.bestLocation), from: self)
                }
            }
        }
    }

    @objc private func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if connectionButton.isFocused {
                myPreferredFocusedView = notificationButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if preferredFocusedView == notificationButton {
                myPreferredFocusedView = helpButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            } else if preferredFocusedView == settingsButton || settingsButton.isFocused {
                myPreferredFocusedView = notificationButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            } else if preferredFocusedView == helpButton {
                myPreferredFocusedView = upgradeButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if preferredFocusedView == notificationButton {
                myPreferredFocusedView = settingsButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            } else if preferredFocusedView == helpButton {
                myPreferredFocusedView = notificationButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            } else if preferredFocusedView == upgradeButton {
                myPreferredFocusedView = helpButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }
    }

    func bindViews() {
        connectionStateViewModel.selectedNodeSubject.subscribe(onNext: {
            self.setConnectionLabelValuesForSelectedNode(selectedNode: $0)
        }).disposed(by: disposeBag)
        self.configureBestLocation(selectBestLocation: true)
        connectionStateViewModel.displayLocalIPAddress(force: true)
        latencyViewModel.loadAllServerLatency().observe(on: MainScheduler.asyncInstance).subscribe(onCompleted: { [self] in
            self.configureBestLocation()
        }, onError: { _ in
        }).disposed(by: disposeBag)
        connectionStateViewModel.connectedState.subscribe(onNext: {
            self.animateConnectedState(with: $0)
        }).disposed(by: disposeBag)

        connectionStateViewModel.ipAddressSubject.subscribe(onNext: {
            self.showSecureIPAddressState(ipAddress: $0)
        }).disposed(by: disposeBag)
        viewModel.session.subscribe(onNext: {
            self.checkSessionChanges(session: $0)
        }).disposed(by: disposeBag)

        viewModel.wifiNetwork.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.refreshProtocol(from: $0)
        }).disposed(by: disposeBag)

        viewModel.selectedProtocol.subscribe(onNext: {_ in
            self.refreshProtocol(from: nil)
        }).disposed(by: disposeBag)
        viewModel.selectedPort.subscribe(onNext: {_ in
            self.refreshProtocol(from: nil)
        }).disposed(by: disposeBag)

        connectionStateViewModel.selectedNodeSubject.subscribe(onNext: {
            self.setConnectionLabelValuesForSelectedNode(selectedNode: $0)
        }).disposed(by: disposeBag)
        setFlagImages()

        serverListViewModel.configureVPNTrigger.subscribe(onNext: {_ in
            self.configureVPN()
        }).disposed(by: disposeBag)

        favNodesListViewModel.configureVPNTrigger.subscribe(onNext: {_ in
            self.configureVPN()
        }).disposed(by: disposeBag)

        staticIPListViewModel.configureVPNTrigger.subscribe(onNext: {_ in
            self.configureVPN()
        }).disposed(by: disposeBag)

        languageManager.activelanguage.subscribe(onNext: { [self] _ in
            localisation()
        }, onError: { _ in }).disposed(by: disposeBag)

        viewModel.locationOrderBy.subscribe(on: MainScheduler.instance).bind(onNext: { _ in
            self.setFlagImages()
        }).disposed(by: self.disposeBag)

        Observable.combineLatest(viewModel.session, languageManager.activelanguage)
            .subscribe(on: MainScheduler.instance).bind(onNext: { [weak self] (session, _) in
                self?.setUpgradeButton(session: session)
        }).disposed(by: self.disposeBag)

    }

    func loadLastConnected() {
        if let node = viewModel.getLastConnectedNode(), let nodeModel = node.getFavNodeModel() {
            guard let countryCode = nodeModel.countryCode, let dnsHostname = nodeModel.dnsHostname, let hostname = nodeModel.hostname, let serverAddress = nodeModel.ipAddress, let nickName = nodeModel.nickName, let cityName = nodeModel.cityName, let groupId = Int(nodeModel.groupId ?? "1") else { return }
            self.vpnManager.selectedNode = SelectedNode(countryCode: countryCode, dnsHostname: dnsHostname, hostname: hostname, serverAddress: serverAddress, nickName: nickName, cityName: cityName, staticIPCredentials: node.staticIPCredentials.first?.getModel(), customConfig: viewModel.getCustomConfig(customConfigID: node.customConfigId), groupId: groupId)
            if (self.vpnManager.selectedNode?.wgPublicKey == nil || self.vpnManager.selectedNode?.ip3 == nil) && node.customConfigId == nil && vpnManager.isDisconnected() {
                if self.vpnManager.selectedNode?.cityName == Fields.Values.bestLocation {
                    self.configureBestLocation(selectBestLocation: true)
                } else {
                    self.vpnManager.selectAnotherNode()
                }
                logger.logD(self, "Last connected node couldn't be found on disk. Loading another node in same group.")
            }
        }
        if self.vpnManager.selectedNode == nil {
            guard let bestLocationValue = try? viewModel.bestLocation.value(), bestLocationValue.isInvalidated == false else { return }
            let bestLocation = bestLocationValue.getBestLocationModel()
            guard let countryCode = bestLocation.countryCode, let dnsHostname = bestLocation.dnsHostname, let hostname = bestLocation.hostname, let serverAddress = bestLocation.ipAddress, let nickName = bestLocation.nickName, let cityName = bestLocation.cityName, let groupId = bestLocation.groupId else { return }
            self.vpnManager.selectedNode = SelectedNode(countryCode: countryCode, dnsHostname: dnsHostname, hostname: hostname, serverAddress: serverAddress, nickName: nickName, cityName: cityName, groupId: groupId)
            logger.logD(self, "Last connected node couldn't be found on disk. Best location node is set as selected.")

        }
    }

    func localisation() {
        locationsLabel.text = TextsAsset.Permission.locationPermissionLabel
        upgradeButton.updateText()
    }

    func loadLastConnection() {
        viewModel.lastConnection.subscribe(onNext: { lastconnection in
            self.protocolLabel.text = lastconnection?.protocolType
            self.portLabel.text = lastconnection?.port
        }).disposed(by: disposeBag)
    }

    func configureBestLocation(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        viewModel.bestLocation.filter {$0?.isInvalidated == false}.bind(onNext: { bestLocation in
            guard let bestLocation = bestLocation , bestLocation.isInvalidated == false else { return }
            self.logger.logD(self, "Configuring best location.")
            self.bestLocation = bestLocation.getBestLocationModel()
            if selectBestLocation && self.vpnManager.selectedNode == nil {
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

    func setFlagImages() {
        self.viewModel.serverList.subscribe(on: MainScheduler.instance).subscribe( onNext: { [self] results in
            self.viewModel.sortServerListUsingUserPreferences(isForStreaming: false, servers: results) { serverSectionsOrdered in
                if serverSectionsOrdered.count > 2 {
                    self.firstServer.image = UIImage(named: "\(serverSectionsOrdered[0].server?.countryCode?.lowercased() ?? "")-s")
                    self.secondServer.image = UIImage(named: "\(serverSectionsOrdered[1].server?.countryCode?.lowercased() ?? "")-s")
                    self.thirdServer.image = UIImage(named: "\(serverSectionsOrdered[2].server?.countryCode?.lowercased() ?? "")-s")
                }

            }
        }).disposed(by: self.disposeBag)

    }

    func setConnectionLabelValuesForSelectedNode(selectedNode: SelectedNode) {
        DispatchQueue.main.async {
            self.connectedServerLabel.text = selectedNode.nickName
            if selectedNode.cityName == Fields.Values.bestLocation {
                self.connectedCityLabel.text = TextsAsset.bestLocation
            } else {
                self.connectedCityLabel.text = selectedNode.cityName
            }
            self.flagView.image = UIImage(named: "\(selectedNode.countryCode.lowercased())-l")
        }
    }

    func setUpgradeButton(session: Session?) {
        if let session = session {
            if session.isUserPro {
                upgradeButton.isHidden = true
            } else {
                upgradeButton.isHidden = false
                upgradeButton.dataLeft.text = "\(session.getDataLeft()) \(TextsAsset.left.uppercased())"
            }
        }
    }

    func showSecureIPAddressState(ipAddress: String) {
        UIView.animate(withDuration: 0.25) {[weak self] in
            guard let self = self else { return }
            self.ipLabel.text = ipAddress.formatIpAddress().maxLength(length: 15)
            if self.vpnManager.isConnected() {
                self.ipIcon.image = UIImage(named: ImagesAsset.secure)
            } else {
                self.ipIcon.image = UIImage(named: ImagesAsset.unsecure)
            }
        }
    }

    func animateConnectedState(with info: ConnectionStateInfo) {

        var status = info.state.statusText
        if status == TextsAsset.Status.connecting || status == TextsAsset.Status.connectivityTest {
            status = TextsAsset.Status.on
        }
        self.statusLabel.text = status
        self.statusLabel.textColor = info.state.statusColor
        self.flagBackgroundView.backgroundColor = info.state.backgroundColor
        self.protocolLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
        self.portLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
        self.connectionButtonRing.image = UIImage(named: info.state.connectButtonRingTv)
        self.connectionButton.setBackgroundImage(UIImage(named: info.state.connectButtonTV), for: .normal)
        self.connectionButton.setBackgroundImage(UIImage(named: info.state.connectButtonTvFocused), for: .focused)
        if [.connecting].contains(info.state) { self.connectionButtonRing.rotate() } else { self.connectionButtonRing.stopRotating() }
        self.refreshProtocol(from: try? viewModel.wifiNetwork.value())

    }

    func refreshProtocol(from network: WifiNetwork?) {
        self.vpnManager.getVPNConnectionInfo { [self] info in
            if info?.status == .disconnecting ||  info?.status == .invalid {
                return
            }
            if info != nil && [.connected, .connecting].contains(info!.status) {
                protocolLabel.text = info?.selectedProtocol
                portLabel.text = info?.selectedPort
                return
            }
            if ((try? self.viewModel.connectionMode.value()) ?? DefaultValues.connectionMode) == Fields.Values.manual {
                self.protocolLabel.text = try? self.viewModel.selectedProtocol.value()
                self.portLabel.text = try? self.viewModel.selectedPort.value()
                return
            }
            self.protocolLabel.text = WifiManager.shared.selectedProtocol ?? protocolLabel.text
            self.portLabel.text = WifiManager.shared.selectedPort ?? portLabel.text
        }
    }

    @IBAction func connectButtonPressed(_ sender: Any) {
        VPNManager.shared.resetProperties()
        disableConnectButton()
        if statusLabel.text?.contains(TextsAsset.Status.off) ?? false {
            logger.logE(MainViewController.self, "User tapped to connect.")
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if isOnline {
                configureVPN()
            } else {
                enableConnectButton()
                // displayInternetConnectionLostAlert()
            }
        } else {
            logger.logD(self, "User tapped to disconnect.")
            connectionStateViewModel.disconnect()
        }
    }

    func disableConnectButton() {
        connectionButton.isUserInteractionEnabled = false
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(enableConnectButton), userInfo: nil, repeats: false)
    }

    @objc func enableConnectButton() {
        self.connectionButton.isUserInteractionEnabled = true
    }

    @objc func configureVPN(bypassConnectingCheck: Bool = false) {
        if !viewModel.isPrivacyPopupAccepted() {
            showPrivacyConfirmationPopup()
            return
        } else if vpnManager.isConnecting() && bypassConnectingCheck == false {
            self.displayConnectingAlert()
            logger.logD(self, "User attempted to connect while in connecting state.")
            return
        } else if (try? viewModel.session.value())?.status == 2 && !vpnManager.isCustomConfigSelected() {
            self.showOutOfDataPopup()
            vpnManager.disconnectActiveVPNConnection(setDisconnect: true, disableConnectIntent: true)
            logger.logD(self, "User attempted to connect when out of data.")
            return
        }
        vpnManager.connectIntent = false
        vpnManager.userTappedToDisconnect = false
        vpnManager.isOnDemandRetry = false
        // viewModel.reconnect()

        if WifiManager.shared.isConnectedWifiTrusted() {
            // Add trusted network popup
            //  router?.routeTo(to: .trustedNetwork, from: self)
        } else {
            viewModel.reconnect()
        }
    }

    private func checkSessionChanges(session: Session?) {
        guard let session = session else { return }
        logger.logD(self, "Looking for account state changes.")
        if session.status == 3 {
            logger.logD(self, "User is banned.")
            router?.routeTo(to: RouteID.bannedAccountPopup, from: self)
            return
        } else if session.status == 2 {
            if !viewModel.didShowOutOfDataPopup {
                logger.logD(self, "User is out of data.")
                self.showOutOfDataPopup()
                self.viewModel.didShowOutOfDataPopup = true
            }
            return
        }
        guard let oldSession = viewModel.oldSession else { return }
        if !session.isPremium && oldSession.isPremium {
            logger.logD(self, "User Pro plan is expired.")
            self.showProPlanExpiredPopup()
            return
        }
    }

    private func showOutOfDataPopup() {
        if vpnManager.isConnected() && !vpnManager.isCustomConfigSelected() {
            connectionStateViewModel.disconnect()
        }
        self.logger.logD(self, "Displaying Out Of Data Popup.")
        router?.routeTo(to: RouteID.outOfDataAccountPopup, from: self)

    }

    private func showProPlanExpiredPopup() {
        if !viewModel.didShowProPlanExpiredPopup {
            DispatchQueue.main.async {
                self.router?.routeTo(to: RouteID.proPlanExpireddAccountPopup, from: self)
            }
            self.viewModel.didShowProPlanExpiredPopup = true
        }
    }

    private func showPrivacyConfirmationPopup() {
        if !viewModel.isPrivacyPopupAccepted() {
            router?.routeTo(to: .privacyView(completionHandler: {
                self.configureVPN()
            }), from: self)
        }
    }

    private func displayConnectingAlert() {
        AlertManager.shared.showSimpleAlert(
            viewController: self,
            title: TextsAsset.ConnectingAlert.title,
            message: TextsAsset.ConnectingAlert.message,
            buttonText: TextsAsset.okay
        )
    }

}

extension MainViewController: ServerListTableViewDelegate {
    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel) {

        if let premiumOnly = group.premiumOnly, let isUserPro = sessionManager.session?.isPremium {
            if premiumOnly && !isUserPro {
                router.routeTo(to: .upgrade(promoCode: nil, pcpID: nil, shouldBeRoot: false), from: self)
            } else {
                serverListViewModel.setSelectedServerAndGroup(server: server,
                                                              group: group)
            }
        }
    }
    func showUpgradeView() {
        router?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil, shouldBeRoot: false), from: self)
    }
    func showExpiredAccountView() {
        router?.routeTo(to: RouteID.proPlanExpireddAccountPopup, from: self)
    }

    func showOutOfDataPopUp() {
         showOutOfDataPopup()
    }
    func reloadTable(cell: UITableViewCell) { }
}

extension MainViewController: FavNodesListTableViewDelegate {
    func setSelectedFavNode(favNode: FavNodeModel) {
        favNodesListViewModel.setSelectedFavNode(favNode: favNode)
    }
}

extension MainViewController: StaticIPListTableViewDelegate {
    func setSelectedStaticIP(staticIP: StaticIPModel) {
        staticIPListViewModel.setSelectedStaticIP(staticIP: staticIP)
    }
}

extension MainViewController: BestLocationConnectionDelegate {
    func connectToBestLocation() {
        serverListViewModel.connectToBestLocation()
    }
}

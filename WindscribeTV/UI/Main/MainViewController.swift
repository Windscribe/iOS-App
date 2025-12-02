//
//  MainViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import NetworkExtension
import RxSwift
import Swinject
import UIKit

class MainViewController: PreferredFocusedViewController {
    @IBOutlet var settingsButton: SettingButton!
    @IBOutlet var notificationButton: NotificationButton!
    @IBOutlet var helpButton: HelpButton!
    @IBOutlet var flagView: UIImageView!
    @IBOutlet var backgroundView: UIView!
    var flagBackgroundView: UIView!
    var flagBottomGradientView: UIImageView!
    var gradient,
        backgroundGradient,
        flagBottomGradient: CAGradientLayer!
    @IBOutlet var ipLabel: UILabel!
    @IBOutlet var ipIcon: UIImageView!
    @IBOutlet var portLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var protocolLabel: UILabel!
    @IBOutlet var connectedCityLabel: UILabel!
    @IBOutlet var connectedServerLabel: UILabel!
    @IBOutlet var dividerView: UIView!
    @IBOutlet var connectionButton: UIButton!
    @IBOutlet var connectionButtonRing: UIImageView!

    @IBOutlet var upgradeButton: UpgradeButton!
    @IBOutlet var bestLocationImage: UIImageView!
    @IBOutlet var firstServer: UIImageView!
    @IBOutlet var secondServer: UIImageView!
    @IBOutlet var thirdServer: UIImageView!
    @IBOutlet var locationsLabel: UILabel!
    @IBOutlet var nextViewButton: UIButton!

    // MARK: Properties

    var viewModel: MainViewModel!
    var ipInfoViewModel: IPInfoViewModelType!
    var vpnConnectionViewModel: ConnectionViewModelType!
    var latencyViewModel: LatencyViewModel!
    var serverListViewModel: ServerListViewModelType!
    var favNodesListViewModel: FavouriteListViewModelType!
    var staticIPListViewModel: StaticIPListViewModelType!
    var router: HomeRouter!
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    var logger: FileLogger!
    var isFromServer: Bool = false
    lazy var sessionManager = Assembler.resolve(SessionManager.self)
    lazy var userSessionRepository = Assembler.resolve(UserSessionRepository.self)
    private lazy var languageManager: LanguageManager = Assembler.resolve(LanguageManager.self)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViews()
        setupSwipeDownGesture()
        loadLastConnection()
        sessionManager.setSessionTimer()
        sessionManager.listenForSessionChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        logger.logD("MainViewController", "Main view will appear")
        viewModel.keepSessionUpdated()
        super.viewWillAppear(animated)
        myPreferredFocusedView = connectionButton
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    @objc func appEnteredForeground() {
        viewModel.keepSessionUpdated()
    }

    private func setupUI() {
        myPreferredFocusedView = connectionButton
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        view.backgroundColor = UIColor.clear
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
        view.addSubview(flagBackgroundView)

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
        statusLabel.layer.cornerRadius = statusLabel.frame.height / 2
        statusLabel.clipsToBounds = true
        statusLabel.backgroundColor = .whiteWithOpacity(opacity: 0.24)
        statusLabel.font = .bold(size: 35)

        connectedCityLabel.font = .bold(size: 135)
        connectedServerLabel.font = .text(size: 120)
        connectionButton.layer.cornerRadius = connectionButton.frame.height / 2
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

    @IBAction func settingsPressed(_: Any) {
        router.routeTo(to: RouteID.preferences, from: self)
    }

    @IBAction func notificationsClicked(_: Any) {
        router.routeTo(to: RouteID.newsFeed, from: self)
    }

    @IBAction func helpClicked(_: Any) {
        router.routeTo(to: RouteID.support, from: self)
    }

    @IBAction func upgradeButtonPressed(_: Any) {
        router.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil, shouldBeRoot: false), from: self)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for press in presses {
            if press.type == .downArrow {
                if nextViewButton.isFocused {
                    myPreferredFocusedView = connectionButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                    router.routeTo(to: .serverList(bestLocation: vpnConnectionViewModel.getBestLocation()), from: self)
                }
            } else if press.type == .upArrow {
                if connectionButton.isFocused {
                    myPreferredFocusedView = notificationButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                }
            } else if press.type == .rightArrow {
                if preferredFocusedView == notificationButton {
                    myPreferredFocusedView = helpButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                } else if preferredFocusedView == settingsButton || UIScreen.main.focusedView == settingsButton {
                    myPreferredFocusedView = notificationButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                } else if preferredFocusedView == helpButton {
                    myPreferredFocusedView = upgradeButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                }

            } else if press.type == .leftArrow {
                if preferredFocusedView == notificationButton {
                    myPreferredFocusedView = settingsButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                } else if preferredFocusedView == helpButton {
                    myPreferredFocusedView = notificationButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                } else if preferredFocusedView == upgradeButton {
                    myPreferredFocusedView = helpButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
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
            if preferredFocusedView == notificationButton || preferredFocusedView == settingsButton || settingsButton.isFocused || preferredFocusedView == helpButton {
                myPreferredFocusedView = connectionButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            } else if connectionButton.isFocused {
                DispatchQueue.main.async {
                    self.router.routeTo(to: .serverList(bestLocation: self.vpnConnectionViewModel.getBestLocation()), from: self)
                }
            } else {
                myPreferredFocusedView = connectionButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if connectionButton.isFocused {
                myPreferredFocusedView = notificationButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if preferredFocusedView == notificationButton {
                myPreferredFocusedView = helpButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            } else if preferredFocusedView == settingsButton || settingsButton.isFocused {
                myPreferredFocusedView = notificationButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            } else if preferredFocusedView == helpButton {
                myPreferredFocusedView = upgradeButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if preferredFocusedView == notificationButton {
                myPreferredFocusedView = settingsButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            } else if preferredFocusedView == helpButton {
                myPreferredFocusedView = notificationButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            } else if preferredFocusedView == upgradeButton {
                myPreferredFocusedView = helpButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    func bindViews() {
        configureBestLocation(selectBestLocation: false)
        vpnConnectionViewModel.displayLocalIPAddress()
        setFlagImages()

        vpnConnectionViewModel.selectedLocationUpdated.sink { _ in
            self.setConnectionLabelValuesForSelectedNode()
        }.store(in: &cancellables)

        ipInfoViewModel.ipAddressSubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ipAddress in
                self?.showSecureIPAddressState(ipAddress: ipAddress)
            }
            .store(in: &cancellables)

        vpnConnectionViewModel.connectedState.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.animateConnectedState(with: $0)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showPrivacyTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showPrivacyConfirmationPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showUpgradeRequiredTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showOutOfDataPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showAuthFailureTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showAuthFailurePopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showNoConnectionAlertTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.displayInternetConnectionLostAlert()
        }).disposed(by: disposeBag)

        latencyViewModel.loadAllServerLatency(
            onAllServerCompletion: {
                self.configureBestLocation()
            }, onStaticCompletion: { },
            onCustomConfigCompletion: { },
            onExitCompletion: {
                self.configureBestLocation()
            })

        viewModel.sessionModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.checkSessionChanges(session: session)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            viewModel.wifiNetwork.asPublisher().replaceError(with: nil),
            vpnConnectionViewModel.selectedProtoPort.asPublisher().replaceError(with: nil)
        )
        .sink { (network, protocolPort) in
            self.refreshProtocol(from: network, with: protocolPort)
        }.store(in: &cancellables)

        languageManager.activelanguage.sink { [self] _ in
            localisation()
        }.store(in: &cancellables)

        viewModel.locationOrderBy.subscribe(on: MainScheduler.instance).bind(onNext: { _ in
            self.setFlagImages()
        }).disposed(by: disposeBag)

        Publishers.CombineLatest(
            viewModel.sessionModel,
            languageManager.activelanguage
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] session, _ in
            self?.setUpgradeButton(session: session)
        }.store(in: &cancellables)
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

    func noSelectedNodeToConnect() -> Bool {
        return vpnConnectionViewModel.getSelectedCountryCode() == ""
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
            guard let displayingGroup = try? self.viewModel.serverList.value().flatMap({ $0.groups }).filter({ $0.id == bestLocation.groupId }).first else { return }
            let isGroupProOnly = displayingGroup.premiumOnly
            if let isUserPro = viewModel.sessionModel.value?.isPremium,
               vpnConnectionViewModel.isDisconnected(),
               isGroupProOnly,
               !isUserPro {
                vpnConnectionViewModel.selectBestLocation(with: locationId)
            }
        }
    }

    func setFlagImages() {
        self.viewModel.serverList.subscribe(on: MainScheduler.instance).subscribe( onNext: { [self] results in
            self.viewModel.sortServerListUsingUserPreferences(ignoreStreaming: true, isForStreaming: false, servers: results) { serverSectionsOrdered in
                if serverSectionsOrdered.count > 2 {
                    self.firstServer.image = UIImage(named: "\(serverSectionsOrdered[0].server?.countryCode.lowercased() ?? "")-s")
                    self.secondServer.image = UIImage(named: "\(serverSectionsOrdered[1].server?.countryCode.lowercased() ?? "")-s")
                    self.thirdServer.image = UIImage(named: "\(serverSectionsOrdered[2].server?.countryCode.lowercased() ?? "")-s")
                }

            }
        }).disposed(by: self.disposeBag)

    }

    func setConnectionLabelValuesForSelectedNode() {
        let location = vpnConnectionViewModel.getSelectedCountryInfo()
        guard !location.countryCode.isEmpty else { return }
        DispatchQueue.main.async {
            self.connectedServerLabel.text = location.nickName
            self.connectedCityLabel.text = location.cityName
            self.flagView.image = UIImage(named: "\(location.countryCode.lowercased())-l")
        }
    }

    func setUpgradeButton(session: SessionModel?) {
        DispatchQueue.main.async {
            if let session = session {
                if session.isUserPro {
                    self.upgradeButton.isHidden = true
                } else {
                    self.upgradeButton.isHidden = false
                    self.upgradeButton.dataLeft.text = "\(session.getDataLeft()) \(TextsAsset.left.uppercased())"
                }
            } else {
                // Hide upgrade button when session is nil (not loaded yet)
                self.upgradeButton.isHidden = true
            }
        }
    }

    func showSecureIPAddressState(ipAddress: String) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }
            self.ipLabel.text = ipAddress.formatIpAddress().maxLength(length: 15)
        }
    }

    func animateConnectedState(with info: ConnectionStateInfo) {
        var status = info.state.statusText
        if status == TextsAsset.Status.connecting || status == TextsAsset.Status.connectivityTest {
            status = TextsAsset.Status.on
        }
        statusLabel.text = status
        statusLabel.textColor = info.state.statusColor
        flagBackgroundView.backgroundColor = info.state.backgroundColor
        protocolLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
        portLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
        connectionButtonRing.image = UIImage(named: info.state.connectButtonRingTv)
        connectionButton.setBackgroundImage(UIImage(named: info.state.connectButtonTV), for: .normal)
        connectionButton.setBackgroundImage(UIImage(named: info.state.connectButtonTvFocused), for: .focused)
        if [.connecting].contains(info.state) { connectionButtonRing.rotate() } else { connectionButtonRing.stopRotating() }
    }

    func refreshProtocol(from network: WifiNetwork?, with protoPort: ProtocolPort?) {
        DispatchQueue.main.async {
            guard let protoPort = protoPort else { return }
            self.protocolLabel.text = protoPort.protocolName
            self.portLabel.text = protoPort.portName
        }
    }

    @IBAction func connectButtonPressed(_: Any) {
        disableConnectButton()
        if statusLabel.text?.contains(TextsAsset.Status.off) ?? false {
            logger.logI("MainViewController", "User tapped to connect.")
            let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
            if isOnline {
                enableVPNConnection()
            } else {
                enableConnectButton()
            }
        } else {
            logger.logD("MainViewController", "User tapped to disconnect.")
            disableVPNConnection()
        }
    }

    func disableConnectButton() {
        connectionButton.isUserInteractionEnabled = false
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(enableConnectButton), userInfo: nil, repeats: false)
    }

    @objc func enableConnectButton() {
        connectionButton.isUserInteractionEnabled = true
    }

    @objc func enableVPNConnection() {
        vpnConnectionViewModel.enableConnection()
    }

    @objc func disableVPNConnection() {
        vpnConnectionViewModel.disableConnection()
    }

    private func checkSessionChanges(session: SessionModel?) {
        guard let session = session else { return }
        logger.logD("MainViewController", "Looking for account state changes.")
        if session.status == 3 {
            logger.logD("MainViewController", "User is banned.")
            router?.routeTo(to: RouteID.bannedAccountPopup, from: self)
            return
        } else if session.status == 2 {
            if !viewModel.didShowOutOfDataPopup {
                logger.logD("MainViewController", "User is out of data.")
                showOutOfDataPopup()
                viewModel.didShowOutOfDataPopup = true
            }
            return
        }
        guard let oldSession = viewModel.oldSession else { return }
        if !session.isPremium && oldSession.isPremium {
            logger.logD("MainViewController", "User Pro plan is expired.")
            showProPlanExpiredPopup()
            return
        }
    }

    private func showOutOfDataPopup() {
        logger.logD("MainViewController", "Displaying Out Of Data Popup.")
        router?.routeTo(to: RouteID.outOfDataAccountPopup, from: self)
    }

    private func showProPlanExpiredPopup() {
        if !viewModel.didShowProPlanExpiredPopup {
            DispatchQueue.main.async {
                self.router?.routeTo(to: RouteID.proPlanExpireddAccountPopup, from: self)
            }
            viewModel.didShowProPlanExpiredPopup = true
        }
    }

    private func showPrivacyConfirmationPopup() {
        if !viewModel.isPrivacyPopupAccepted() {
            router?.routeTo(to: .privacyView(completionHandler: {
                self.enableVPNConnection()
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

    private func showAuthFailurePopup() {
        AlertManager.shared.showSimpleAlert(viewController: self,
                                            title: TextsAsset.AuthFailure.title,
                                            message: TextsAsset.AuthFailure.message,
                                            buttonText: TextsAsset.okay)
    }

    private func displayInternetConnectionLostAlert() {
        AlertManager.shared.showSimpleAlert(
            viewController: self,
            title: TextsAsset.NoInternetAlert.title,
            message: TextsAsset.NoInternetAlert.message,
            buttonText: TextsAsset.okay
        )
    }
}

extension MainViewController: ServerListTableViewDelegate {
    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel) {
        if let isUserPro = userSessionRepository.sessionModel?.isPremium {
            if group.premiumOnly && !isUserPro {
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

    func reloadTable(cell _: UITableViewCell) {}
}

extension MainViewController: FavouriteListTableViewDelegate {
    func setSelectedFavourite(favourite: GroupModel) {
        favNodesListViewModel.setSelectedFav(favourite: favourite)
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

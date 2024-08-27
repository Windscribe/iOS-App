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

class MainViewController: UIViewController {
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
    var router: HomeRouter!
    let disposeBag = DisposeBag()
    let vpnManager = VPNManager.shared
    var logger: FileLogger!
    var myPreferredFocusedView: UIView?
    var isFromServer: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViews()
        setupSwipeDownGesture()
        // Do any additional setup after loading the view.
    }

    override var preferredFocusedView: UIView? {

       return myPreferredFocusedView
    }
    
    private func setupUI() {
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
        backgroundGradient.colors = [UIColor.lightMidnight.withAlphaComponent(0.75).cgColor, UIColor.clear.cgColor]
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

        connectedCityLabel.font = .bold(size: 100)
        connectedServerLabel.font = .text(size: 85)
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
    
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for press in presses {
            if press.type == .downArrow {
                if nextViewButton.isFocused {
                    myPreferredFocusedView = connectionButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                    router.routeTo(to: .serverList, from: self)
                }
            } else if press.type == .upArrow {
                if connectionButton.isFocused {
                    myPreferredFocusedView = notificationButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                }
            }
            else if press.type == .rightArrow {
                if preferredFocusedView == notificationButton {
                    myPreferredFocusedView = helpButton
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                } else if preferredFocusedView == settingsButton {
                    myPreferredFocusedView = notificationButton
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
                }
            }
        }
    }
    
    private func setupSwipeDownGesture() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }

    @objc private func handleSwipeDown(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if preferredFocusedView == nextViewButton {
                myPreferredFocusedView = connectionButton
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
                router.routeTo(to: .serverList, from: self)
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
            self.setUpgradeButton(session: $0)
        }).disposed(by: disposeBag)

        viewModel.selectedPort.subscribe(onNext: {
            self.portLabel.text = $0
        }).disposed(by: disposeBag)

        viewModel.selectedProtocol.subscribe(onNext: {
            self.protocolLabel.text = $0
        }).disposed(by: disposeBag)
        connectionStateViewModel.selectedNodeSubject.subscribe(onNext: {
            self.setConnectionLabelValuesForSelectedNode(selectedNode: $0)
        }).disposed(by: disposeBag)
        setFlagImages()

    }

    func configureBestLocation(selectBestLocation: Bool = false, connectToBestLocation: Bool = false) {
        viewModel.bestLocation.bind(onNext: { bestLocation in
            guard let bestLocation = bestLocation , bestLocation.isInvalidated == false else { return }
            self.logger.logD(self, "Configuring best location.")
            if selectBestLocation {// && self.vpnManager.isDisconnected() {
                self.vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode, dnsHostname: bestLocation.dnsHostname, hostname: bestLocation.hostname, serverAddress: bestLocation.ipAddress, nickName: bestLocation.nickName, cityName: bestLocation.cityName, autoPicked: true, groupId: bestLocation.groupId)
            }
            if connectToBestLocation {
                self.logger.logD(self, "Forcing to connect to best location.")
                // self.configureVPN()
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
        guard let results = try? viewModel.serverList.value() else { return }
        if results.count == 0 { return }
        self.viewModel.sortServerListUsingUserPreferences(isForStreaming: false, servers: results) { serverSectionsOrdered in
            self.firstServer.image = UIImage(named: serverSectionsOrdered[0].server?.countryCode ?? "")
            self.secondServer.image = UIImage(named: serverSectionsOrdered[1].server?.countryCode ?? "")
            self.thirdServer.image = UIImage(named: serverSectionsOrdered[2].server?.countryCode ?? "")
        }
    }

    func setConnectionLabelValuesForSelectedNode(selectedNode: SelectedNode) {
        DispatchQueue.main.async {
            self.connectedServerLabel.text = selectedNode.nickName
            if selectedNode.cityName == Fields.Values.bestLocation {
                self.connectedCityLabel.text = TextsAsset.bestLocation
            } else {
                self.connectedCityLabel.text = selectedNode.cityName
            }
            self.flagView.image = UIImage(named: selectedNode.countryCode)
        }
    }

    func setUpgradeButton(session: Session?) {
        if let session = session {
            if session.isUserPro {
                upgradeButton.isHidden = true
            } else {
                upgradeButton.isHidden = false
                upgradeButton.dataLeft?.text = "\(session.getDataLeft()) \(TextsAsset.left.uppercased())"
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
        self.statusLabel.text = info.state.statusText
        self.statusLabel.textColor = info.state.statusColor
        self.flagBackgroundView.backgroundColor = info.state.backgroundColor
        self.protocolLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
        self.portLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
        self.connectionButtonRing.image = UIImage(named: info.state.connectButtonRingTv)
        self.connectionButton.setBackgroundImage(UIImage(named: info.state.connectButtonTV), for: .normal)
        self.connectionButton.setBackgroundImage(UIImage(named: info.state.connectButton), for: .focused)
    }

}

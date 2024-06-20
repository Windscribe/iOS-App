//
//  MainViewController+Status.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import NetworkExtension

extension ConnectionState {
    var backgroundColor: UIColor {
        switch self {
        case .connected, .test: .connectedStartBlue
        case .connecting, .automaticFailed: .connectingStartBlue
        case .disconnecting: .disconnectedStartBlack
        case .disconnected: .lightMidnight
        }
    }
    var backgroundOpacity: Float { [.disconnecting].contains(self) ? 0.10 : 0.25 }
    var statusText: String {
        switch self {
        case .test: TextsAsset.Status.connectivityTest
        case .connected: TextsAsset.Status.on
        case .connecting: TextsAsset.Status.connecting
        case .disconnected, .disconnecting: TextsAsset.Status.off
        case .automaticFailed: ""
        }
    }
    var statusColor: UIColor {
        switch self {
        case .connected, .test: .seaGreen
        case .connecting: .lowGreen
        case .disconnecting, .disconnected: .white
        case .automaticFailed: .failedConnectionYellow
        }
    }
    var statusImage: String { self == .automaticFailed ? ImagesAsset.protocolFailed : ImagesAsset.connectionSpinner }
    var statusAlpha: CGFloat { [.connected, .test, .connecting, .automaticFailed].contains(self) ? 1.0 : 0.5 }
    var statusViewColor: UIColor { ([.disconnected, .disconnecting].contains(self) ? UIColor.white : .midnight).withAlphaComponent(0.25) }
    var preferredProtocolBadge: String {
        switch self {
        case .connected, .test: ImagesAsset.preferredProtocolBadgeOn
        case .connecting: ImagesAsset.preferredProtocolBadgeConnecting
        case .disconnecting, .disconnected, .automaticFailed: ImagesAsset.preferredProtocolBadgeOff
        }
    }
    var connectButtonRing: String {
        switch self {
        case .connected, .test: ImagesAsset.connectButtonRing
        case .connecting: ImagesAsset.connectingButtonRing
        case .disconnecting, .disconnected, .automaticFailed: ImagesAsset.failedConnectionButtonRing
        }
    }
    var connectButton: String { [.disconnected, .disconnecting].contains(self) ? ImagesAsset.disconnectedButton : ImagesAsset.connectButton }
}

extension MainViewController {
    func bindConnectionStateViewModel() {
        connectionStateViewModel.displayLocalIPAddress(force: true)

        connectionStateViewModel.selectedNodeSubject.subscribe(onNext: {
            self.setConnectionLabelValuesForSelectedNode(selectedNode: $0)
        }).disposed(by: disposeBag)

        connectionStateViewModel.loadLatencyValuesSubject.subscribe(onNext: {
            self.loadLatencyValues(force: $0.force, selectBestLocation: $0.selectBestLocation, connectToBestLocation: $0.connectToBestLocation)
        }).disposed(by: disposeBag)

        connectionStateViewModel.showAutoModeScreenTrigger.subscribe(onNext: {
            guard let viewControllers = self.navigationController?.viewControllers,
                  !viewControllers.contains(where: { $0 is ProtocolSetPreferredViewController }),
                  !viewControllers.contains(where: { $0 is ProtocolSwitchViewController })
            else { return }

            self.router?.routeTo(to: RouteID.protocolSwitchVC(delegate: self.protocolSwitchViewModel, type: .failure), from: self)
        }).disposed(by: disposeBag)

        connectionStateViewModel.openNetworkHateUsDialogTrigger.subscribe(onNext: {
            self.router?.routeTo(to: RouteID.protocolSetPreferred(type: .fail, delegate: self.protocolSwitchViewModel, protocolName: ""), from: self)
        }).disposed(by: disposeBag)

        connectionStateViewModel.pushNotificationPermissionsTrigger.subscribe(onNext: {
            self.popupRouter?.routeTo(to: .pushNotifications, from: self)
        }).disposed(by: disposeBag)

        connectionStateViewModel.siriShortcutTrigger.subscribe(onNext: {
            self.displaySiriShortcutPopup()
        }).disposed(by: disposeBag)

        connectionStateViewModel.requestLocationTrigger.subscribe(onNext: {
            self.locationManagerViewModel.requestLocationPermission {
                self.router?.routeTo(to: RouteID.protocolSetPreferred(type: .connected, delegate: nil, protocolName: ConnectionManager.shared.getNextProtocol().protocolName), from: self)
            }
        }).disposed(by: disposeBag)

        connectionStateViewModel.enableConnectTrigger.subscribe(onNext: {
            self.enableConnectButton()
        }).disposed(by: disposeBag)

        connectionStateViewModel.ipAddressSubject.subscribe(onNext: {
            self.showSecureIPAddressState(ipAddress: $0)
        }).disposed(by: disposeBag)

        connectionStateViewModel.autoModeSelectorHiddenChecker.subscribe(onNext: {
            $0(self.autoModeSelectorView.isHidden)
        }).disposed(by: disposeBag)

        connectionStateViewModel.connectedState.subscribe(onNext: {
            self.animateConnectedState(with: $0)
        }).disposed(by: disposeBag)
    }

    func animateConnectedState(with info: ConnectionStateInfo) {
        DispatchQueue.main.async {
            var duration = 0.25
            if info.state == .automaticFailed {
                guard let connectedWifi = info.connectedWifi else { return }
                self.protocolLabel.text = "\(connectedWifi.protocolType.uppercased()) \(TextsAsset.Status.failed)"
                duration = 0.0
            }
            UIView.transition(with: self.topNavBarImageView, duration: duration, options: .transitionCrossDissolve, animations: {
                self.setTopNavImage(white: [.disconnected, .disconnecting].contains(info.state))
            }, completion: nil)
            UIView.animate(withDuration: duration) {
                self.flagBackgroundView.backgroundColor = info.state.backgroundColor
                self.topNavBarImageView.layer.opacity = info.state.backgroundOpacity
                if [.connected, .connecting].contains(info.state) {
                    self.changeProtocolArrow.isHidden = info.isCustomConfigSelected
                } else {
                    self.changeProtocolArrow.isHidden = [.disconnected, .disconnecting].contains(info.state)
                }
                self.connectivityTestImageView.isHidden = [.connecting, .automaticFailed, .connected, .disconnected, .disconnecting].contains(info.state)
                if case .test = info.state {
                    self.connectivityTestImageView.image = UIImage.gifImageWithName("dots")
                }
                self.statusDivider.isHidden = [.automaticFailed].contains(info.state)
                self.statusImageView.image = UIImage(named: info.state.statusImage)
                self.statusImageView.isHidden = [.test, .connected, .disconnected, .disconnecting].contains(info.state)
                self.statusView.backgroundColor = info.state.statusViewColor
                self.statusLabel.text = info.state.statusText
                self.statusLabel.isHidden = [.test, .connecting, .automaticFailed].contains(info.state)
                self.statusLabel.textColor = info.state.statusColor
                self.protocolLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
                self.portLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
                self.preferredProtocolBadge.image = UIImage(named: info.state.preferredProtocolBadge)
                self.setCircumventCensorshipBadge(color: info.state.statusColor.withAlphaComponent(info.state.statusAlpha))
                self.connectButtonRingView.isHidden = [.disconnected, .disconnecting].contains(info.state)
                self.connectButtonRingView.image = UIImage(named: info.state.connectButtonRing)
                self.connectButton.setImage(UIImage(named: info.state.connectButton), for: .normal)
                if info.state == .disconnected {
                    let isOnline = ((try? self.viewModel.appNetwork.value().status == .connected) != nil)
                    if !isOnline {
                        self.showNoInternetConnection()
                    }
                    if info.customConfig != nil {
                       self.disableAutoSecureViews()
                    } else {
                        self.enableAutoSecureViews()
                    }
                }
                if info.state == .connecting {
                    self.viewModel.refreshProtocolInfo()
                    self.hideAutoSecureViews()
                }
            }
            if case .test = info.state { self.hideSplashView() }
            if [.connected, .disconnected, .test].contains(info.state) { self.connectButtonRingView.stopRotating() } else { self.connectButtonRingView.rotate() }
            if [.connecting].contains(info.state) { self.statusImageView.rotate() } else { self.statusImageView.stopRotating() }
            self.updateRefreshControls()
            self.viewModel.refreshProtocolInfo()
        }
    }

    private func setCircumventCensorshipBadge(color: UIColor? = nil) {
        circumventCensorshipBadge.image = UIImage(named: ImagesAsset.circumventCensorship)
        if preferredBadgeConstraints[2].constant > 0 {
            circumventCensorshipBadgeConstraints[1].constant = 10
        } else {
            circumventCensorshipBadgeConstraints[1].constant = 0
        }
        if viewModel.isAntiCensorshipEnabled() {
            circumventCensorshipBadgeConstraints[2].constant = 14
            circumventCensorshipBadgeConstraints[3].constant = 12
            changeProtocolArrowConstraints[1].constant = 6
        } else {
            circumventCensorshipBadgeConstraints[2].constant = 0
            circumventCensorshipBadgeConstraints[3].constant = 0
            changeProtocolArrowConstraints[1].constant = 0
        }
        if let color = color {
            circumventCensorshipBadge.setImageColor(color: color)
        }
        circumventCensorshipBadge.layoutIfNeeded()
        changeProtocolArrow.layoutIfNeeded()
    }

    private func nonAnimationConnectionState() {
        self.preferredProtocolBadge.isUserInteractionEnabled = false
    }
}

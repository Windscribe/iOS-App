//
//  MainViewController+Status.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import NetworkExtension
import RxSwift
import UIKit

extension MainViewController {
    func bindVPNConnectionsViewModel() {
        vpnConnectionViewModel.connectedState.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.animateConnectedState(with: $0)
            self.setCircumventCensorshipBadge(color: $0.state.statusColor.withAlphaComponent($0.state.statusAlpha))
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showPrivacyTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showPrivacyConfirmationPopup(willConnectOnAccepting: true)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showUpgradeRequiredTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showOutOfDataPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.showConnectionFailedTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showConnectionFailed()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.ipAddressSubject.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.showSecureIPAddressState(ipAddress: $0)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.selectedLocationUpdatedSubject.subscribe(onNext: {
            self.updateSelectedLocationUI()
        }).disposed(by: disposeBag)

        Observable.combineLatest(viewModel.wifiNetwork,
                                 vpnConnectionViewModel.selectedProtoPort).bind { (network, protocolPort) in
                self.refreshProtocol(from: network, with: protocolPort)
        }.disposed(by: disposeBag)

        vpnConnectionViewModel.showAutoModeScreenTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            guard let viewControllers = self.navigationController?.viewControllers,
                  !viewControllers.contains(where: { $0 is ProtocolSetPreferredViewController }),
                  !viewControllers.contains(where: { $0 is ProtocolSwitchViewController })
            else { return }

            self.router?.routeTo(to: RouteID.protocolSwitchVC(delegate: self.protocolSwitchViewModel, type: .failure), from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.openNetworkHateUsDialogTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
                self.router?.routeTo(to: RouteID.protocolSetPreferred(type: .fail, delegate: self.protocolSwitchViewModel), from: self)
            }).disposed(by: disposeBag)

        vpnConnectionViewModel.pushNotificationPermissionsTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.popupRouter?.routeTo(to: .pushNotifications, from: self)
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.siriShortcutTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.displaySiriShortcutPopup()
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.requestLocationTrigger.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.locationManagerViewModel.requestLocationPermission {
                self.router?.routeTo(to: RouteID.protocolSetPreferred(type: .connected, delegate: nil), from: self)
            }
        }).disposed(by: disposeBag)

        vpnConnectionViewModel.loadLatencyValuesSubject.subscribe(onNext: {
            self.loadLatencyValues(force: $0.force, connectToBestLocation: $0.connectToBestLocation)
        }).disposed(by: disposeBag)
    }

    func updateConnectedState() {
        if let state = try? vpnConnectionViewModel.connectedState.value() {
            animateConnectedState(with: state, animated: false)
        }
    }

    func animateConnectedState(with info: ConnectionStateInfo, animated: Bool = true) {
        DispatchQueue.main.async {
            var duration = animated ? 0.25 : 0.0
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
                    self.addOrRemoveTapOnProtocolLabel(!info.isCustomConfigSelected)
                } else {
                    self.changeProtocolArrow.isHidden = [.disconnected, .disconnecting].contains(info.state)
                    self.addOrRemoveTapOnProtocolLabel(![.disconnected, .disconnecting].contains(info.state))
                }
                self.connectivityTestImageView.isHidden = [.connecting, .automaticFailed, .connected, .disconnected, .disconnecting].contains(info.state)
                if case .testing = info.state {
                    self.connectivityTestImageView.image = UIImage.gifImageWithName("dots")
                }
                self.statusDivider.isHidden = [.automaticFailed].contains(info.state)
                self.statusImageView.image = UIImage(named: info.state.statusImage)
                self.statusImageView.isHidden = [.testing, .connected, .disconnected, .disconnecting].contains(info.state)
                self.statusView.backgroundColor = info.state.statusViewColor
                self.statusLabel.text = info.state.statusText
                self.statusLabel.isHidden = [.testing, .connecting, .automaticFailed].contains(info.state)
                self.statusLabel.textColor = info.state.statusColor
                self.protocolLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
                self.portLabel.textColor = info.state.statusColor.withAlphaComponent(info.state.statusAlpha)
                self.preferredProtocolBadge.image = UIImage(named: info.state.preferredProtocolBadge)
                self.trustedNetworkIcon.image = UIImage(named: info.trustedNetworkImage)
                self.setCircumventCensorshipBadge(color: info.state.statusColor.withAlphaComponent(info.state.statusAlpha))
                self.connectButtonRingView.isHidden = [.disconnected, .disconnecting].contains(info.state)
                self.connectButtonRingView.image = UIImage(named: info.state.connectButtonRing)
                self.connectButton.setImage(UIImage(named: info.state.connectButton), for: .normal)
                if info.state == .disconnected {
                    let isOnline = ((try? self.viewModel.appNetwork.value().status == .connected) != nil)
                    if !isOnline {
                        self.showNoInternetConnection()
                    }
                    if info.isCustomConfigSelected {
                        self.disableAutoSecureViews()
                    } else {
                        self.enableAutoSecureViews()
                    }
                }
                if info.state == .connecting {
                    self.hideAutoSecureViews()
                }
            }
            if [.connected, .disconnected, .testing].contains(info.state) { self.connectButtonRingView.stopRotating() } else { self.connectButtonRingView.rotate() }
            if [.connecting].contains(info.state) { self.statusImageView.rotate() } else { self.statusImageView.stopRotating() }
            self.updateRefreshControls()
            self.yourIPIcon.image = UIImage(named: info.state == .connected ? ImagesAsset.secure : ImagesAsset.unsecure)
        }
    }

    func addOrRemoveTapOnProtocolLabel(_ add: Bool) {
        if add {
            protocolLabel.isUserInteractionEnabled = true
            portLabel.isUserInteractionEnabled = true
        } else {
            protocolLabel.isUserInteractionEnabled = false
            portLabel.isUserInteractionEnabled = false
        }
    }

    func setCircumventCensorshipBadge(color: UIColor? = nil) {
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
            circumventCensorshipBadge.tintColor = color
        }
        circumventCensorshipBadge.layoutIfNeeded()
        changeProtocolArrow.layoutIfNeeded()
    }

    private func nonAnimationConnectionState() {
        preferredProtocolBadge.isUserInteractionEnabled = false
    }

    private func updateSelectedLocationUI() {
        let location = vpnConnectionViewModel.getSelectedCountryInfo()
        guard !location.countryCode.isEmpty else { return }
        DispatchQueue.main.async {
            self.showFlagAnimation(countryCode: location.countryCode,
                                   autoPicked: self.vpnConnectionViewModel.isBestLocationSelected() || self.vpnConnectionViewModel.isCustomConfigSelected())
            self.connectedServerLabel.text = location.nickName
            self.connectedCityLabel.text = location.cityName
        }
    }
}

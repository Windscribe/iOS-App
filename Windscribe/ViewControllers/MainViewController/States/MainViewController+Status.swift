//
//  MainViewController+Status.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension MainViewController {
    func setConnectionState() {
        if statusLabel.text?.contains(TextsAsset.Status.connecting) ?? false {
            setConnectingState()
            return
        }
        if VPNManager.shared.connectivityTestTimer?.isValid ?? false {
            return setConnectivityTest()
        }
        switch VPNManager.shared.connectionStatus() {
        case .connected:
            setConnectedState()
        case .connecting:
            setConnectingState()
        case .disconnected:
            setDisconnectedState()
        case .disconnecting:
            setDisconnectingState()
        default: return
        }
    }

    func setConnectivityTestState() {
        DispatchQueue.main.async {
            UIView.transition(with: self.topNavBarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.setTopNavImage(white: false)
            }, completion: nil)
            UIView.animate(withDuration: 0.25) {
                self.flagBackgroundView.backgroundColor = UIColor.connectedStartBlue
                self.topNavBarImageView.layer.opacity = 0.25
                self.statusLabel.text = TextsAsset.Status.connectivityTest
                self.statusLabel.isHidden = true
                self.statusDivider.isHidden = false
                self.statusImageView.stopRotating()
                self.statusImageView.isHidden = true
                let logoImageData = try? Data(contentsOf: Bundle.main.url(forResource: "dots", withExtension: "gif")!)
                let logoGifImage = UIImage.gifImageWithData(logoImageData!)
                self.connectivityTestImageView.image = logoGifImage
                self.connectivityTestImageView.isHidden = false
                self.statusView.backgroundColor = UIColor.midnight.withAlphaComponent(0.25)
                self.statusLabel.textColor = UIColor.seaGreen
                self.protocolLabel.textColor = UIColor.seaGreen
                self.portLabel.textColor = UIColor.seaGreen
                self.preferredProtocolBadge.image = UIImage(named: ImagesAsset.preferredProtocolBadgeOn)
                self.connectButtonRingView.isHidden = false
                self.setCircumventCensorshipBadge(color: .seaGreen)
                self.connectButtonRingView.image = UIImage(named: ImagesAsset.connectButtonRing)
                self.connectButton.setImage(UIImage(named: ImagesAsset.connectButton), for: .normal)
                self.connectButtonRingView.stopRotating()
            }
        }
    }

    func setConnectedState() {
        if statusLabel.text == TextsAsset.Status.connectivityTest {
            HapticFeedbackGenerator.shared.run(level: .medium)
        }
        DispatchQueue.main.async {
            UIView.transition(with: self.topNavBarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.setTopNavImage(white: false)
            }, completion: nil)
            UIView.animate(withDuration: 0.25) {
                self.flagBackgroundView.backgroundColor = UIColor.connectedStartBlue
                self.topNavBarImageView.layer.opacity = 0.25
                self.statusDivider.isHidden = false
                self.statusLabel.text = TextsAsset.Status.on
                if !self.vpnManager.isCustomConfigSelected() {
                    self.changeProtocolArrow.isHidden = false
                }
                self.statusLabel.isHidden = false
                self.statusImageView.isHidden = true
                self.connectivityTestImageView.isHidden = true
                self.statusView.backgroundColor = UIColor.midnight.withAlphaComponent(0.25)
                self.statusLabel.textColor = UIColor.seaGreen
                self.protocolLabel.textColor = UIColor.seaGreen
                self.portLabel.textColor = UIColor.seaGreen
                self.connectButtonRingView.isHidden = false
                self.setCircumventCensorshipBadge(color: .seaGreen)
                self.connectButtonRingView.image = UIImage(named: ImagesAsset.connectButtonRing)
                self.connectButton.setImage(UIImage(named: ImagesAsset.connectButton), for: .normal)
                self.connectButtonRingView.stopRotating()
            }
            self.protocolSelectionChanged()
        }
    }

    func setProtocolAndPortLabels() {
        if let customConfig = VPNManager.shared.selectedNode?.customConfig, let protocolType = customConfig.protocolType, let port = customConfig.port {
            protocolLabel.text = protocolType
            portLabel.text = port
        } else {
            protocolSelectionChanged(force: true)
        }
    }

    func setDisconnectedState() {
        DispatchQueue.main.async {
            if self.statusLabel.text == TextsAsset.Status.on {
                HapticFeedbackGenerator.shared.run(level: .medium)
            }
            UIView.transition(with: self.topNavBarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.setTopNavImage(white: true)
            }, completion: nil)
            UIView.animate(withDuration: 0.25) {
                self.flagBackgroundView.backgroundColor = UIColor.lightMidnight
                self.topNavBarImageView.layer.opacity = 0.10
                self.statusDivider.isHidden = false
                self.statusLabel.text = TextsAsset.Status.off
                self.preferredProtocolBadge.isUserInteractionEnabled = false
                self.changeProtocolArrow.isHidden = true
                self.statusLabel.isHidden = false
                self.statusImageView.isHidden = true
                self.connectivityTestImageView.isHidden = true
                self.statusImageView.stopRotating()
                self.statusView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
                self.statusLabel.textColor = UIColor.white
                self.protocolLabel.textColor = UIColor.white.withAlphaComponent(0.5)
                self.portLabel.textColor = UIColor.white.withAlphaComponent(0.5)
                self.preferredProtocolBadge.image = UIImage(named: ImagesAsset.preferredProtocolBadgeOff)
                self.setCircumventCensorshipBadge(color: .white.withAlphaComponent(0.5))
                self.connectButtonRingView.isHidden = true
                self.connectButtonRingView.stopRotating()
                self.connectButton.setImage(UIImage(named: ImagesAsset.disconnectedButton), for: .normal)
                if !ReachabilityManager.shared.internetConnectionAvailable() {
                    self.showNoInternetConnection()
                }
                if VPNManager.shared.selectedNode?.customConfig != nil {
                    self.disableAutoSecureViews()
                } else {
                    self.enableAutoSecureViews()
                }
                self.protocolSelectionChanged()
            }
        }
    }

    private func setCircumventCensorshipBadge(color: UIColor? = nil) {
        circumventCensorshipBadge.image = UIImage(named: ImagesAsset.circumventCensorship)
        if preferredBadgeConstraints[2].constant > 0 {
            circumventCensorshipBadgeConstraints[1].constant = 10
        } else {
            circumventCensorshipBadgeConstraints[1].constant = 0
        }
        if SharedSecretDefaults.shared.getBool(key: SharedKeys.circumventCensorship) {
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

    func setPreferredProtocolBadgeVisibility(hidden: Bool) {
        if hidden {
            preferredBadgeConstraints[2].constant = 0
            preferredBadgeConstraints[3].constant = 0
        } else {
            preferredBadgeConstraints[2].constant = 10
            preferredBadgeConstraints[3].constant = 8
        }
        preferredProtocolBadge.layoutIfNeeded()
        changeProtocolArrow.layoutIfNeeded()
    }

    @objc func setConnectingState() {
        DispatchQueue.main.async {
            if !ReachabilityManager.shared.internetConnectionAvailable() {
                self.setDisconnectedState()
                return
            }
            UIView.transition(with: self.topNavBarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.setTopNavImage(white: false)
            }, completion: nil)
            UIView.animate(withDuration: 0.25) {
                self.flagBackgroundView.backgroundColor = UIColor.connectingStartBlue
                self.topNavBarImageView.layer.opacity = 0.25
                self.statusDivider.isHidden = false
                self.statusLabel.isHidden = true
                self.statusLabel.text = TextsAsset.Status.connecting
                self.statusImageView.image = UIImage(named: ImagesAsset.connectionSpinner)
                self.statusImageView.isHidden = false
                self.connectivityTestImageView.isHidden = true
                self.statusImageView.rotate()
                self.statusView.backgroundColor = UIColor.midnight.withAlphaComponent(0.25)
                self.statusLabel.textColor = UIColor.white
                self.protocolLabel.textColor = UIColor.lowGreen
                self.portLabel.textColor = UIColor.lowGreen
                self.preferredProtocolBadge.image = UIImage(named: ImagesAsset.preferredProtocolBadgeConnecting)
                self.setCircumventCensorshipBadge(color: .lowGreen)
                self.connectButtonRingView.isHidden = false
                self.connectButton.setImage(UIImage(named: ImagesAsset.connectButton), for: .normal)
                self.connectButtonRingView.image = UIImage(named: ImagesAsset.connectingButtonRing)
                self.connectButtonRingView.rotate()

                self.setProtocolAndPortLabels()
                self.hideAutoSecureViews()
            }
            self.protocolSelectionChanged()
        }
    }

    func setAutomaticModeFailedState() {
        if flagBackgroundView.backgroundColor != UIColor.connectingStartBlue {
            UIView.transition(with: topNavBarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.setTopNavImage(white: false)
            }, completion: nil)
            UIView.animate(withDuration: 0.25) {
                self.flagBackgroundView.backgroundColor = UIColor.connectingStartBlue
            }
        }
        guard let connectedWifi = WifiManager.shared.connectedWifi else { return }
        topNavBarImageView.layer.opacity = 0.25
        protocolLabel.text = "\(connectedWifi.protocolType.uppercased()) \(TextsAsset.Status.failed)"
        portLabel.text = ""
        statusLabel.isHidden = true
        statusImageView.stopRotating()
        statusDivider.isHidden = true
        statusImageView.image = UIImage(named: ImagesAsset.protocolFailed)
        statusImageView.isHidden = false
        connectivityTestImageView.isHidden = true
        statusView.backgroundColor = UIColor.midnight.withAlphaComponent(0.25)
        statusLabel.textColor = UIColor.failedConnectionYellow
        protocolLabel.textColor = UIColor.failedConnectionYellow
        portLabel.textColor = UIColor.failedConnectionYellow
        preferredProtocolBadge.image = UIImage(named: ImagesAsset.preferredProtocolBadgeOff)
        setCircumventCensorshipBadge()
        connectButtonRingView.isHidden = false
        connectButton.setImage(UIImage(named: ImagesAsset.connectButton), for: .normal)
        connectButtonRingView.image = UIImage(named: ImagesAsset.failedConnectionButtonRing)
        connectButtonRingView.rotate()
    }

    func setDisconnectingState() {
        if statusLabel.text == "\(TextsAsset.Status.disconnecting)..." { return }
        UIView.transition(with: topNavBarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.setTopNavImage(white: true)
        }, completion: nil)
        UIView.animate(withDuration: 0.25) {
            self.flagBackgroundView.backgroundColor = UIColor.disconnectedStartBlack
            self.topNavBarImageView.layer.opacity = 0.10
            self.statusLabel.isHidden = false
            self.statusLabel.text = TextsAsset.Status.off
            self.preferredProtocolBadge.isUserInteractionEnabled = false
            self.changeProtocolArrow.isHidden = true
            self.statusImageView.isHidden = true
            self.connectivityTestImageView.isHidden = true
            self.statusView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
            self.statusLabel.textColor = UIColor.white
            self.protocolLabel.textColor = UIColor.white.withAlphaComponent(0.5)
            self.portLabel.textColor = UIColor.white.withAlphaComponent(0.5)
            self.preferredProtocolBadge.image = UIImage(named: ImagesAsset.preferredProtocolBadgeOff)
            self.setCircumventCensorshipBadge(color: .white.withAlphaComponent(0.5))
            self.connectButtonRingView.isHidden = true
            self.connectButtonRingView.image = UIImage(named: ImagesAsset.failedConnectionButtonRing)
            self.connectButtonRingView.rotate()
            self.connectButton.setImage(UIImage(named: ImagesAsset.disconnectedButton), for: .normal)
        }
    }

    func continueAnimations() {
        setConnectionState()
    }
}

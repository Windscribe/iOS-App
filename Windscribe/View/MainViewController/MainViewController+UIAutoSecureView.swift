//
//  MainViewController+UIAutoSecureView.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

extension MainViewController {
    func addAutoSecureViews() {
        let darkModeNotUsed = BehaviorSubject(value: true)

        autoSecureLabel = UILabel()
        autoSecureLabel.adjustsFontSizeToFitWidth = true
        autoSecureLabel.text = TextsAsset.Whitelist.title.uppercased()
        autoSecureLabel.font = UIFont.bold(size: 12)
        autoSecureLabel.layer.opacity = 0.5
        autoSecureLabel.textAlignment = .left
        autoSecureLabel.textColor = UIColor.white
        view.addSubview(autoSecureLabel)

        autoSecureInfoButton = ImageButton()
        autoSecureInfoButton.addTarget(self, action: #selector(autoSecureInfoButtonTapped), for: .touchUpInside)
        autoSecureInfoButton.setImage(UIImage(named: ImagesAsset.upgradeInfo), for: .normal)
        view.addSubview(autoSecureInfoButton)

        trustNetworkSwitch = SwitchButton(isDarkMode: darkModeNotUsed)
        trustNetworkSwitch.addTarget(self, action: #selector(trustNetworkSwitchTapped), for: .touchUpInside)
        view.addSubview(trustNetworkSwitch)

        cellDivider1 = UIView()
        cellDivider1.layer.opacity = 0.05
        cellDivider1.backgroundColor = UIColor.white
        view.addSubview(cellDivider1)

        preferredProtocolLabel = UILabel()
        preferredProtocolLabel.text = TextsAsset.PreferredProtocol.title.uppercased()
        preferredProtocolLabel.layer.opacity = 0.5
        preferredProtocolLabel.textColor = UIColor.white
        preferredProtocolLabel.font = UIFont.bold(size: 12)
        preferredProtocolLabel.textAlignment = .left
        view.addSubview(preferredProtocolLabel)

        preferredProtocolInfoButton = ImageButton()
        preferredProtocolInfoButton.addTarget(self, action: #selector(preferredProtocolInfoButtonTapped), for: .touchUpInside)
        preferredProtocolInfoButton.setImage(UIImage(named: ImagesAsset.upgradeInfo), for: .normal)
        view.addSubview(preferredProtocolInfoButton)

        preferredProtocolSwitch = SwitchButton(isDarkMode: darkModeNotUsed)
        preferredProtocolSwitch.addTarget(self, action: #selector(preferredProtocolSwitchTapped), for: .touchUpInside)
        view.addSubview(preferredProtocolSwitch)

        protocolSelectionLabel = UILabel()
        protocolSelectionLabel.text = TextsAsset.General.protocolType.uppercased()
        protocolSelectionLabel.font = UIFont.text(size: 12)
        protocolSelectionLabel.layer.opacity = 0.5
        protocolSelectionLabel.textAlignment = .left
        protocolSelectionLabel.textColor = UIColor.white
        view.addSubview(protocolSelectionLabel)

        protocolDropdownButton = DropdownButton(isDarkMode: darkModeNotUsed)
        protocolDropdownButton.delegate = self
        protocolDropdownButton.setTitle(TextsAsset.General.protocols[0])
        protocolDropdownButton.layer.opacity = 0.5
        view.addSubview(protocolDropdownButton)

        manualViewDivider1 = UIView()
        manualViewDivider1.layer.opacity = 0.05
        manualViewDivider1.backgroundColor = UIColor.white
        view.addSubview(manualViewDivider1)

        portSelectionLabel = UILabel()
        portSelectionLabel.text = TextsAsset.General.port.uppercased()
        portSelectionLabel.font = UIFont.text(size: 12)
        portSelectionLabel.layer.opacity = 0.5
        portSelectionLabel.textAlignment = .left
        portSelectionLabel.textColor = UIColor.white
        view.addSubview(portSelectionLabel)

        portDropdownButton = DropdownButton(isDarkMode: darkModeNotUsed)
        portDropdownButton.layer.opacity = 0.5
        portDropdownButton.delegate = self
        view.addSubview(portDropdownButton)

        addAutoSecureConstraints()
    }

    func localizeAutoSecure() {
        autoSecureLabel.text = TextsAsset.Whitelist.title.uppercased()
        preferredProtocolLabel.text = TextsAsset.PreferredProtocol.title.uppercased()
        protocolSelectionLabel.text = TextsAsset.General.protocolType.uppercased()
        portSelectionLabel.text = TextsAsset.General.port.uppercased()
    }

    func addAutoSecureConstraints() {
        autoSecureLabel.translatesAutoresizingMaskIntoConstraints = false
        autoSecureInfoButton.translatesAutoresizingMaskIntoConstraints = false
        trustNetworkSwitch.translatesAutoresizingMaskIntoConstraints = false
        cellDivider1.translatesAutoresizingMaskIntoConstraints = false
        preferredProtocolLabel.translatesAutoresizingMaskIntoConstraints = false
        preferredProtocolInfoButton.translatesAutoresizingMaskIntoConstraints = false
        preferredProtocolSwitch.translatesAutoresizingMaskIntoConstraints = false
        manualViewDivider1.translatesAutoresizingMaskIntoConstraints = false
        protocolSelectionLabel.translatesAutoresizingMaskIntoConstraints = false
        portSelectionLabel.translatesAutoresizingMaskIntoConstraints = false
        portDropdownButton.translatesAutoresizingMaskIntoConstraints = false
        protocolDropdownButton.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: autoSecureLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: autoSecureLabel as Any, attribute: .top, relatedBy: .equal, toItem: trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: 23),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: autoSecureInfoButton as Any, attribute: .centerY, relatedBy: .equal, toItem: autoSecureLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoSecureInfoButton as Any, attribute: .left, relatedBy: .equal, toItem: autoSecureLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: autoSecureInfoButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: autoSecureInfoButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: trustNetworkSwitch as Any, attribute: .centerY, relatedBy: .equal, toItem: autoSecureLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: trustNetworkSwitch as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: trustNetworkSwitch as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: trustNetworkSwitch as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 45),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: cellDivider1 as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: cellDivider1 as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cellDivider1 as Any, attribute: .top, relatedBy: .equal, toItem: trustNetworkSwitch, attribute: .bottom, multiplier: 1.0, constant: 13),
            NSLayoutConstraint(item: cellDivider1 as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: preferredProtocolLabel as Any, attribute: .top, relatedBy: .equal, toItem: cellDivider1, attribute: .bottom, multiplier: 1.0, constant: 18),
            NSLayoutConstraint(item: preferredProtocolLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: preferredProtocolLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: preferredProtocolInfoButton as Any, attribute: .centerY, relatedBy: .equal, toItem: preferredProtocolLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: preferredProtocolInfoButton as Any, attribute: .left, relatedBy: .equal, toItem: preferredProtocolLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: preferredProtocolInfoButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: preferredProtocolInfoButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: preferredProtocolSwitch as Any, attribute: .centerY, relatedBy: .equal, toItem: preferredProtocolLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: preferredProtocolSwitch as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: preferredProtocolSwitch as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: preferredProtocolSwitch as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 45),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: protocolSelectionLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: protocolSelectionLabel as Any, attribute: .top, relatedBy: .equal, toItem: preferredProtocolLabel, attribute: .bottom, multiplier: 1.0, constant: 18),
            NSLayoutConstraint(item: protocolSelectionLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: protocolDropdownButton as Any, attribute: .centerY, relatedBy: .equal, toItem: protocolSelectionLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: protocolDropdownButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: protocolDropdownButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: protocolDropdownButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 90),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: manualViewDivider1 as Any, attribute: .left, relatedBy: .equal, toItem: protocolSelectionLabel, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: manualViewDivider1 as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: manualViewDivider1 as Any, attribute: .top, relatedBy: .equal, toItem: protocolSelectionLabel, attribute: .bottom, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: manualViewDivider1 as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: portSelectionLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: portSelectionLabel as Any, attribute: .top, relatedBy: .equal, toItem: manualViewDivider1, attribute: .bottom, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: portSelectionLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: portDropdownButton as Any, attribute: .centerY, relatedBy: .equal, toItem: portSelectionLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: portDropdownButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: portDropdownButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: portDropdownButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 70),
        ])
    }

    func hideAutoSecureViews() {
        tappedOnScreen()
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn) {
            self.expandButton.imageView?.rotate(360)
            self.expandButton.tag = 0
            self.autoSecureLabel.isHidden = true
            self.autoSecureInfoButton.isHidden = true
            self.trustNetworkSwitch.isHidden = true
            self.preferredProtocolLabel.isHidden = true
            self.preferredProtocolInfoButton.isHidden = true
            self.preferredProtocolSwitch.isHidden = true
            self.protocolSelectionLabel.isHidden = true
            self.protocolDropdownButton.isHidden = true
            self.portSelectionLabel.isHidden = true
            self.portDropdownButton.isHidden = true
            self.manualViewDivider1.isHidden = true
            self.yourIPIcon.layer.opacity = 0.5
            self.yourIPValueLabel.layer.opacity = 0.5
            if !self.searchLocationsView.viewModel.isActive() {
                self.view.removeConstraint(self.cardViewTopConstraint)
                self.cardViewTopConstraint = NSLayoutConstraint(item: self.cardView as Any, attribute: .top, relatedBy: .equal, toItem: self.trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
                self.view.addConstraint(self.cardViewTopConstraint)
                self.view.layoutIfNeeded()
            }
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                self.flagBottomGradientView.layer.opacity = 0.0
            })
        }
    }

    func showAutoSecureViews() {
        let isOnline: Bool = ((try? viewModel.appNetwork.value().status == .connected) != nil)
        DispatchQueue.main.async {
            if !isOnline {
                self.showNoInternetConnection()
                return
            }
            let isNetworkName: Bool = ((try? self.viewModel.appNetwork.value().name) != nil)
            if isNetworkName {
                DispatchQueue.main.async {
                    self.expandAutoSecure()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.expandAutoSecure()
                }
            }

        }
    }

    private func expandAutoSecure() {
        UIView.animate(withDuration: 0.25) {
            self.flagBottomGradientView.layer.opacity = 1.0
            self.expandButton.imageView?.rotate(180)
            self.expandButton.tag = 1
            self.autoSecureLabel.isHidden = false
            self.autoSecureInfoButton.isHidden = false
            self.trustNetworkSwitch.isHidden = false
            self.yourIPIcon.layer.opacity = 0.0
            self.yourIPValueLabel.layer.opacity = 0.0
        }
        self.loadNetworkOptions()
        self.updateNetworkOptions()
    }
}

//
//  MainViewController+AutoSecure.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController {
    func disableAutoSecureViews() {
        autoSecureLabel.isEnabled = false
        trustNetworkSwitch.layer.opacity = 0.5
        preferredProtocolLabel.isEnabled = false
        preferredProtocolSwitch.layer.opacity = 0.5
        protocolSelectionLabel.isEnabled = false
        protocolDropdownButton.layer.opacity = 0.5
        portSelectionLabel.isEnabled = false
        portDropdownButton.layer.opacity = 0.5
    }

    func enableAutoSecureViews() {
        autoSecureLabel.isEnabled = true
        trustNetworkSwitch.layer.opacity = 1.0
        preferredProtocolLabel.isEnabled = true
        preferredProtocolSwitch.layer.opacity = 1.0
        protocolSelectionLabel.isEnabled = true
        protocolDropdownButton.layer.opacity = 1.0
        portSelectionLabel.isEnabled = true
        portDropdownButton.button.isEnabled = true
        portDropdownButton.layer.opacity = 1.0
    }

    func loadNetworkOptions() {
        guard let network =  (try? viewModel.wifiNetwork.value() ?? WifiManager.shared.getConnectedNetwork()) else {
            print("no network detected.... ")
            return
        }
        self.protocolDropdownButton.setTitle(network.preferredProtocol)
        self.portDropdownButton.setTitle(network.preferredPort)

        self.loadPreferredProtocolStatus()
        self.loadTrustNetworkStatus()
    }

    func updateNetworkOptions() {
        guard let network = (try? viewModel.wifiNetwork.value() ?? WifiManager.shared.getConnectedNetwork()) else {
            print("no network detected.... ")
            return }
        trustedNetworkValueLabel.text = network.SSID
        if network.preferredProtocolStatus == true &&
            network.status == false {
            showPreferredProtocolView()
            showProtocolSelectionView()
        } else if network.preferredProtocolStatus == false &&
                    network.status == false {
            hideProtocolSelectionView()
            showPreferredProtocolView()
        } else if network.status == true {
            hidePreferredProtocolView()
        } else if network.status == false {
           showPreferredProtocolView()
        }
        self.preferredProtocolSwitch.setStatus(network.preferredProtocolStatus)
        self.trustNetworkSwitch.setStatus(!network.status)
    }

    func loadTrustNetworkStatus() {
        guard let network = try? viewModel.wifiNetwork.value() else { return }
        self.trustNetworkSwitch.setStatus(!network.status)
        if network.status == true {
            self.hidePreferredProtocolView()
        } else {
            self.showPreferredProtocolView()
        }
    }

    func loadPreferredProtocolStatus() {
        guard let network = try? viewModel.wifiNetwork.value() else { return }
        self.preferredProtocolSwitch.setStatus(network.preferredProtocolStatus)
        if network.preferredProtocolStatus == true && network.status == false {
            self.showProtocolSelectionView()
        } else {
            self.hideProtocolSelectionView()
        }
    }

    @objc func trustNetworkSwitchTapped() {
        guard let network = self.displayingNetwork else { return }
        viewModel.updateTrustNetworkSwitch(network: network, status: !trustNetworkSwitch.status)
        viewModel.updatePreferredProtocolSwitch(network: network, preferredProtocolStatus: false)
        connectionStateViewModel.vpnManager.connectIntent = !trustNetworkSwitch.status
        connectionStateViewModel.vpnManager.updateOnDemandRules()
        self.updateNetworkOptions()
    }

    @objc func preferredProtocolSwitchTapped() {
        tappedOnScreen()
        guard let network = self.displayingNetwork else { return }
        if network.status == true { return }
        preferredProtocolSwitch.toggle()
        viewModel.updatePreferredProtocolSwitch(network: network, preferredProtocolStatus: preferredProtocolSwitch.status)
        self.updateNetworkOptions()
    }

    @objc func tappedOnScreen() {
        if protocolDropdownButton != nil {
            protocolDropdownButton.remove()
        }
        if portDropdownButton != nil {
           portDropdownButton.remove()
        }
    }

    @objc func autoSecureInfoButtonTapped(sender: UIButton) {
        AlertManager.shared.showSimpleAlert(viewController: self, title: "",
                                            message: TextsAsset.Whitelist.description,
                                            buttonText: TextsAsset.okay)
    }

    @objc func preferredProtocolInfoButtonTapped(sender: UIButton) {
        AlertManager.shared.showSimpleAlert(viewController: self, title: "",
                                            message: TextsAsset.PreferredProtocol.description,
                                            buttonText: TextsAsset.okay)
    }
}

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
        guard let network = (try? viewModel.wifiNetwork.value() ?? WifiManager.shared.getConnectedNetwork()) else {
            print("no network detected.... ")
            return
        }
        protocolDropdownButton.setTitle(network.preferredProtocol)
        portDropdownButton.setTitle(network.preferredPort)

        loadPreferredProtocolStatus()
        loadTrustNetworkStatus()
    }

    func updateNetworkOptions() {
        guard let network = (try? viewModel.wifiNetwork.value() ?? WifiManager.shared.getConnectedNetwork()) else {
            print("no network detected.... ")
            return
        }
        trustedNetworkValueLabel.text = network.SSID
        if network.preferredProtocolStatus == true,
           network.status == false
        {
            showPreferredProtocolView()
            showProtocolSelectionView()
        } else if network.preferredProtocolStatus == false,
                  network.status == false
        {
            hideProtocolSelectionView()
            showPreferredProtocolView()
        } else if network.status == true {
            hidePreferredProtocolView()
        } else if network.status == false {
            showPreferredProtocolView()
        }
        preferredProtocolSwitch.setStatus(network.preferredProtocolStatus)
        trustNetworkSwitch.setStatus(!network.status)
    }

    func loadTrustNetworkStatus() {
        guard let network = try? viewModel.wifiNetwork.value() else { return }
        trustNetworkSwitch.setStatus(!network.status)
        if network.status == true {
            hidePreferredProtocolView()
        } else {
            showPreferredProtocolView()
        }
    }

    func loadPreferredProtocolStatus() {
        guard let network = try? viewModel.wifiNetwork.value() else { return }
        preferredProtocolSwitch.setStatus(network.preferredProtocolStatus)
        if network.preferredProtocolStatus == true, network.status == false {
            showProtocolSelectionView()
        } else {
            hideProtocolSelectionView()
        }
    }

    @objc func trustNetworkSwitchTapped() {
        guard let network = displayingNetwork else { return }
        viewModel.updateTrustNetworkSwitch(network: network, status: !trustNetworkSwitch.status)
        viewModel.updatePreferredProtocolSwitch(network: network, preferredProtocolStatus: false)
        vpnConnectionViewModel.vpnManager.connectIntent = !trustNetworkSwitch.status
        vpnConnectionViewModel.vpnManager.updateOnDemandRules()
        updateNetworkOptions()
    }

    @objc func preferredProtocolSwitchTapped() {
        tappedOnScreen()
        guard let network = displayingNetwork else { return }
        if network.status == true { return }
        preferredProtocolSwitch.toggle()
        viewModel.updatePreferredProtocolSwitch(network: network, preferredProtocolStatus: preferredProtocolSwitch.status)
        updateNetworkOptions()
    }

    @objc func tappedOnScreen() {
        if protocolDropdownButton != nil {
            protocolDropdownButton.remove()
        }
        if portDropdownButton != nil {
            portDropdownButton.remove()
        }
    }

    @objc func autoSecureInfoButtonTapped(sender _: UIButton) {
        AlertManager.shared.showSimpleAlert(viewController: self, title: "",
                                            message: TextsAsset.Whitelist.description,
                                            buttonText: TextsAsset.okay)
    }

    @objc func preferredProtocolInfoButtonTapped(sender _: UIButton) {
        AlertManager.shared.showSimpleAlert(viewController: self, title: "",
                                            message: TextsAsset.PreferredProtocol.description,
                                            buttonText: TextsAsset.okay)
    }
}

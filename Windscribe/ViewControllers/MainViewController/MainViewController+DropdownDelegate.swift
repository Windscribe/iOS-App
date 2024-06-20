//
//  MainViewController+DropdownDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: DropdownDelegate {
    func optionSelected(dropdown: Dropdown, option: String, relatedIndex: Int) {
        logger.logD(self, "User tapped to change Trusted Networks.")
        guard let network = self.displayingNetwork else { return }
        switch dropdown {
        case protocolDropdownButton.dropdown:
            protocolDropdownButton.setTitle(option)
            if let protocolName = self.protocolDropdownButton.button.titleLabel?.text, let defaultPort = viewModel.getPortList(protocolName: protocolName)?.first {
                portDropdownButton.setTitle(defaultPort)
                viewModel.updatePreferredProtocol(network: network, proto: option)
                viewModel.updatePreferredPort(network: network, port: defaultPort)
            }
        case portDropdownButton.dropdown:
            portDropdownButton.setTitle(option)
            viewModel.updatePreferredPort(network: network, port: option)
        default: ()
        }
    }
}
// MARK: - DropdownButtonDelegate
extension MainViewController: DropdownButtonDelegate {
    func dropdownButtonTapped(_ sender: DropdownButton) {
        logger.logD(self, "User tapped to open dropdown.")
        tappedOnScreen()
        let dropdown = Dropdown(attachedView: sender)
        dropdown.relatedIndex = 0
        dropdown.dropDownDelegate = self
        switch sender {
        case portDropdownButton:
            if let protocolName = self.protocolDropdownButton.button.titleLabel?.text, let supportedPorts = viewModel.getPortList(protocolName: protocolName) {
                dropdown.options = supportedPorts
            }
        case protocolDropdownButton:
            dropdown.options = TextsAsset.General.protocols
        default: ()
        }
        sender.dropdown = dropdown
        view.addSubview(dropdown)
    }
}

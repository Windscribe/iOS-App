//
//  PreferencesConnectionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class PreferencesConnectionView: UIView {
    var viewModel: ConnectionsViewModelType!

    lazy var connectionModeView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var protocolsView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var portsView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var allwayOnView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var allowLanTraficView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var circumventCensorshipView: SettingsSection = {
        SettingsSection.fromNib()
    }()

    @IBOutlet weak var contentStackView: UIStackView!

    func setup() {
        connectionModeView.populate(with: viewModel.currentConnectionModes(), title: GeneralHelper.getTitle(.connectionMode))
        connectionModeView.delegate = self

        updateProtocols()
        protocolsView.delegate = self
        protocolsView.isHidden = viewModel.getCurrentConnectionMode() == .auto

        updatePorts()
        portsView.delegate = self
        portsView.isHidden = viewModel.getCurrentConnectionMode() == .auto

        allwayOnView.populate(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: GeneralHelper.getTitle(.killSwitch))
        allwayOnView.delegate = self

        allowLanTraficView.populate(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: GeneralHelper.getTitle(.allowLan))
        allowLanTraficView.delegate = self

        circumventCensorshipView.populate(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: TextsAsset.circumventCensorship)
        circumventCensorshipView.delegate = self

        contentStackView.addArrangedSubview(connectionModeView)
        contentStackView.addArrangedSubview(protocolsView)
        contentStackView.addArrangedSubview(portsView)
        contentStackView.addArrangedSubview(allwayOnView)
        contentStackView.addArrangedSubview(allowLanTraficView)
        contentStackView.addArrangedSubview(circumventCensorshipView)
        contentStackView.addArrangedSubview(UIView())
    }

    func updateSelection() {
        connectionModeView.select(option: viewModel.getCurrentConnectionMode().titleValue, animated: false)
        protocolsView.select(option: viewModel.getCurrentProtocol(), animated: false)
        portsView.select(option: viewModel.getCurrentPort(), animated: false)
        allwayOnView.select(option: viewModel.getKillSwitchStatus() ? TextsAsset.General.enabled : TextsAsset.General.disabled, animated: false)
        allowLanTraficView.select(option: viewModel.getAllowLanStatus() ? TextsAsset.General.enabled : TextsAsset.General.disabled, animated: false)
        circumventCensorshipView.select(option: viewModel.getCircumventCensorshipStatus() ? TextsAsset.General.enabled : TextsAsset.General.disabled, animated: false)
    }

    private func updateProtocols() {
        protocolsView.populate(with: viewModel.getProtocols(), title: nil)
    }

    private func updatePorts() {
        portsView.populate(with: viewModel.getPorts(), title: nil)
        portsView.select(option: viewModel.getCurrentPort(), animated: false)
    }
}

extension PreferencesConnectionView: SettingsSectionDelegate {
    func optionWasSelected(for view: SettingsSection, with value: String) {
        if view == connectionModeView {
            let type = ConnectionModeType(titleValue: value)
            viewModel.updateConnectionMode(value: type)
            if type == .manual {
                updateProtocols()
                protocolsView.isHidden = false
                portsView.isHidden = false
            } else {
                protocolsView.isHidden = true
                portsView.isHidden = true
            }
          return
        }
        if view == protocolsView {
            viewModel.updateProtocol(value: value)
            updatePorts()
          return
        }
        if view == portsView {
            viewModel.updatePort(value: value)
          return
        }
        if view == allwayOnView {
            viewModel.updateChangeKillSwitchStatus(status: value == TextsAsset.General.enabled)
          return
        }
        if view == allowLanTraficView {
            viewModel.updateChangeAllowLanStatus(status: value == TextsAsset.General.enabled)
          return
        }
        if view == circumventCensorshipView {
            viewModel.updateCircumventCensorshipStatus(status: value == TextsAsset.General.enabled)
          return
        }
    }
}

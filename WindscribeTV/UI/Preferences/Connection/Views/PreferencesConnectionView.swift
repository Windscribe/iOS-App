//
//  PreferencesConnectionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit

class PreferencesConnectionView: UIView {
    var viewModel: ConnectionsViewModelType!
    private var cancellables = Set<AnyCancellable>()

    lazy var connectionModeView: SettingsSection = .fromNib()

    lazy var protocolsView: SettingsSection = .fromNib()

    lazy var portsView: SettingsSection = .fromNib()

    lazy var circumventCensorshipView: SettingsSection = .fromNib()

    lazy var egressView: SettingsSection = .fromNib()

    lazy var ingressView: SettingsSection = .fromNib()

    @IBOutlet var contentStackView: UIStackView!

    private var egressTitleText: String {
        "\(TextsAsset.Connection.ipStack) - \(TextsAsset.Connection.egress)"
    }

    private var ingressTitleText: String {
        "\(TextsAsset.Connection.ipStack) - \(TextsAsset.Connection.ingress)"
    }
    func setup() {
        updateProtocols()
        updatePorts()

        ingressView.isHidden = true

        connectionModeView.populate(with: GeneralViewType.connectionMode.listOption,
                                    title: GeneralViewType.connectionMode.title)

        circumventCensorshipView.populate(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: TextsAsset.Connection.circumventCensorship)

        egressView.populate(with: viewModel.getIpStackOptions(), title: egressTitleText)
        ingressView.populate(with: viewModel.getIpStackOptions(), title: ingressTitleText)

        protocolsView.isHidden = viewModel.getCurrentConnectionMode() == .auto
        portsView.isHidden = viewModel.getCurrentConnectionMode() == .auto

        portsView.delegate = self
        protocolsView.delegate = self
        connectionModeView.delegate = self
        circumventCensorshipView.delegate = self
        egressView.delegate = self
        ingressView.delegate = self

        for item in [connectionModeView, protocolsView, portsView, circumventCensorshipView, egressView, ingressView] {
            contentStackView.addArrangedSubview(item)
        }
        contentStackView.addArrangedSubview(UIView())

        bindViews()
    }

    func updateSelection() {
        connectionModeView.select(option: viewModel.getCurrentConnectionMode().titleValue, animated: false)
        protocolsView.select(option: viewModel.getCurrentProtocol(), animated: false)
        portsView.select(option: viewModel.getCurrentPort(), animated: false)
        circumventCensorshipView.select(option: viewModel.getCircumventCensorshipStatus() ? TextsAsset.General.enabled : TextsAsset.General.disabled, animated: false)
        egressView.select(option: viewModel.getCurrentEgressProtocol(), animated: false)
        ingressView.select(option: viewModel.getCurrentIngressProtocol(), animated: false)
    }

    private func updateProtocols() {
        protocolsView.populate(with: viewModel.getProtocols(), title: nil)
        protocolsView.select(option: viewModel.getCurrentProtocol(), animated: false)
    }

    private func updatePorts() {
        portsView.populate(with: viewModel.getPorts(), title: nil)
        portsView.select(option: viewModel.getCurrentPort(), animated: false)
    }

    private func updateText() {
        connectionModeView.updateText(with: GeneralViewType.connectionMode.listOption,
                                    title: GeneralViewType.connectionMode.title)

        protocolsView.updateText(with: viewModel.getProtocols(), title: nil)

        portsView.updateText(with: viewModel.getPorts(), title: nil)

        circumventCensorshipView.updateText(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: TextsAsset.Connection.circumventCensorship)

        egressView.updateText(with: viewModel.getIpStackOptions(), title: egressTitleText)
        ingressView.updateText(with: viewModel.getIpStackOptions(), title: ingressTitleText)
    }

    private func bindViews() {
        viewModel.languageUpdatedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateText()
            }
            .store(in: &cancellables)
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
        if view == circumventCensorshipView {
            viewModel.updateCircumventCensorshipStatus(status: value == TextsAsset.General.enabled)
            return
        }
        if view == egressView {
            viewModel.updateEgressProtocol(value: value)
            return
        }
        if view == ingressView {
            viewModel.updateIngressProtocol(value: value)
            return
        }
    }
}

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
    private let disposeBag = DisposeBag()

    lazy var connectionModeView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var protocolsView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var portsView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var circumventCensorshipView: SettingsSection = {
        SettingsSection.fromNib()
    }()

    @IBOutlet weak var contentStackView: UIStackView!

    func setup() {
        updateProtocols()
        updatePorts()

        connectionModeView.populate(with: viewModel.currentConnectionModes(), title: GeneralHelper.getTitle(.connectionMode))

        circumventCensorshipView.populate(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: TextsAsset.circumventCensorship)

        protocolsView.isHidden = viewModel.getCurrentConnectionMode() == .auto
        portsView.isHidden = viewModel.getCurrentConnectionMode() == .auto

        portsView.delegate = self
        protocolsView.delegate = self
        connectionModeView.delegate = self
        circumventCensorshipView.delegate = self

        [connectionModeView, protocolsView, portsView, circumventCensorshipView]
            .forEach {
                contentStackView.addArrangedSubview($0)
            }
        contentStackView.addArrangedSubview(UIView())

        bindViews()
    }

    func updateSelection() {
        connectionModeView.select(option: viewModel.getCurrentConnectionMode().titleValue, animated: false)
        protocolsView.select(option: viewModel.getCurrentProtocol(), animated: false)
        portsView.select(option: viewModel.getCurrentPort(), animated: false)
        circumventCensorshipView.select(option: viewModel.getCircumventCensorshipStatus() ? TextsAsset.General.enabled : TextsAsset.General.disabled, animated: false)
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
        connectionModeView.updateText(with: viewModel.currentConnectionModes(), title: GeneralHelper.getTitle(.connectionMode))

        protocolsView.updateText(with: viewModel.getProtocols(), title: nil)

        portsView.updateText(with: viewModel.getPorts(), title: nil)

        circumventCensorshipView.updateText(with: [TextsAsset.General.enabled, TextsAsset.General.disabled], title: TextsAsset.circumventCensorship)
    }

    private func bindViews() {
        viewModel.languageUpdatedTrigger.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.updateText()
        }.disposed(by: disposeBag)
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
    }
}

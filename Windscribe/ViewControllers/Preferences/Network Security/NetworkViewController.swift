//
//  NetworkViewController.swift
//  Windscribe
//
//  Created by Thomas on 11/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxGesture
import RxSwift
import UIKit

class NetworkViewController: WSNavigationViewController {
    var viewModel: NetworkOptionViewModelType!

    private lazy var secureView = createViewSecure()

    // MARK: - UI ELEMENTs

    lazy var forgetNetworkView: UIView = {
        let vw = UIView()
        vw.rx.anyGesture(.tap()).skip(1).subscribe(onNext: { _ in
            self.viewModel.forgetNetwork { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }).disposed(by: disposeBag)
        let lbl = UILabel()
        lbl.text = TextsAsset.forgetNetwork
        lbl.font = .bold(size: 16)
        vw.addSubview(lbl)
        lbl.fillSuperview(padding: UIEdgeInsets(inset: 16))
        vw.layer.cornerRadius = 8
        viewModel.isDarkMode.bind {
            vw.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
            lbl.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
        }.disposed(by: disposeBag)
        return vw
    }()

    private func createViewSecure() -> ConnectionSecureView {
        let view = ConnectionSecureView(isDarkMode: viewModel.isDarkMode)
        view.titleLabel.text = GeneralHelper.getTitle(.autoSecure)
        view.setImage(UIImage(named: GeneralHelper.getAsset(.autoSecure)))
        view.hideShowExplainIcon()
        view.subTitleLabel.text = GeneralHelper.getDescription(.autoSecure)
        view.connectionSecureViewSwitchAcction = { [weak self] in
            self?.viewModel.toggleAutoSecure()
            self?.viewModel.updateTrustNetwork(self?.viewModel.trustNetworkStatus ?? false, completion: {
                self?.update()
            })
        }
        return view
    }

    lazy var preferredProtocolView: ConnectionModeView = {
        let name = GeneralHelper.getTitle(.preferredProtocol)
        let asset = GeneralHelper.getAsset(.preferredProtocol)
        let description = GeneralHelper.getDescription(.preferredProtocol)
        let vw = ConnectionModeView(title: name,
                                    description: description,
                                    iconAsset: asset,
                                    currentSwitchOption: viewModel.showPreferredProtocol,
                                    currentProtocol: viewModel.preferredProtocol ?? "",
                                    listProtocolOption: viewModel.getProtocols(),
                                    currentPort: viewModel.preferredProtocol ?? "",
                                    listPortOption: viewModel.getDefaultPorts(),
                                    isDarkMode: viewModel.isDarkMode)
        vw.hideShowExpainIcon()
        vw.delegate = self
        return vw
    }()

    // MARK: - UI LIFECYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadNetwork()
        bindViews()
    }

    override func viewWillLayoutSubviews() {
        layoutView.setup()
    }

    // MARK: - helper functions

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupTheme(isDark: isDark)
        }).disposed(by: disposeBag)
        viewModel.networks.subscribe(onNext: { [weak self] networks in
            let allNetworksValid = networks.filter { $0.isInvalidated }.count == 0
            if allNetworksValid {
                self?.loadNetwork()
            }
        }).disposed(by: disposeBag)
    }

    private func setupTheme(isDark: Bool) {
        super.setupViews(isDark: isDark)
    }

    private func setupViews() {
        titleLabel.text = TextsAsset.Preferences.networkSecurity
        setupFillLayoutView()
        layoutView.stackView.addArrangedSubviews([
            secureView,
            preferredProtocolView,
            forgetNetworkView
        ])
        layoutView.stackView.setPadding(UIEdgeInsets(inset: 16))
        layoutView.stackView.spacing = 16
    }

    // MARK: - actions

    private func loadNetwork() {
        viewModel.loadNetwork { [weak self] in
            self?.update()
        }
    }

    private func update() {
        forgetNetworkView.isHidden = viewModel.hideForgetNetwork
        secureView.switchButton.setStatus(viewModel.trustNetworkStatus)
        preferredProtocolView.isHidden = !viewModel.trustNetworkStatus
        preferredProtocolView.updateCurrentPortOption(viewModel.preferredPort ?? "")
        preferredProtocolView.updateCurrentProtocolOption(viewModel.preferredProtocol ?? "")
        preferredProtocolView.setSwitchHeaderStatus(viewModel.showPreferredProtocol)
    }
}

// MARK: - extensions

extension NetworkViewController: ConnectionModeViewDelegate {
    func connectionModeViewExplain() {}

    func connectionModeViewDidChangeMode(_: ConnectionModeType) {}

    func connectionModeViewDidChangeProtocol(_ value: String) {
        viewModel.updatePreferredProtocol(value: value)
        let listPort = viewModel.getPorts(by: value)
        preferredProtocolView.updateListPortOption(listPort)
    }

    func connectionModeViewDidChangePort(_ value: String) {
        viewModel.updatePreferredPort(value: value)
    }

    func connectionModeViewDidSwitch(_: ConnectionModeView, value: Bool) {
        // switch data
        viewModel.updatePreferredProtocolSwitch(value) { [weak self] in
            self?.update()
        }
    }
}

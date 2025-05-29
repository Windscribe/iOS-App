//
//  ConnectionsViewController
//  Windscribe
//
//  Created by Yalcin on 2019-07-09.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import CoreLocation
import RxCocoa
import RxGesture
import RxSwift
import UIKit

class ConnectionViewController: WSNavigationViewController {
    // MARK: - State properties

    var viewModel: ConnectionsViewModelType!, locationManagerViewModel: LocationManagingViewModelType!, router: ConnectionRouter!, logger: FileLogger!

    var currentDropdownView: Dropdown?
    var firstLoadConnectionModeButton: Bool = true
    lazy var circumventCensorshipView: ConnectionSecureView = makeConnectionSecureView(type: .circumventCensorship)

    // MARK: - UI properties

    lazy var networkWhiteListRow: ArrowRowView = {
        let row = ArrowRowView(rowTitle: TextsAsset.Preferences.networkSecurity, isDarkMode: viewModel.isDarkMode)
        return row
    }()

    lazy var connectionModeViewV2: ConnectionModeView = {
        let vw = ConnectionModeView(optionType: GeneralViewType.connectionMode,
                                    optionMode: viewModel.getCurrentConnectionMode(),
                                    currentProtocol: viewModel.getCurrentProtocol(),
                                    listProtocolOption: viewModel.getProtocols(),
                                    currentPort: viewModel.getCurrentPort(),
                                    listPortOption: viewModel.getPorts(),
                                    isDarkMode: viewModel.isDarkMode)
        vw.delegate = self
        return vw
    }()

    lazy var connectedDNSView = {
        let vw = ConnectedDNSView(optionType: viewModel.getCurrentConnectedDNS(),
                                  dnsValue: viewModel.getConnectedDNSValue(),
                                  isDarkMode: viewModel.isDarkMode)
        vw.delegate = self
        return vw
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Connection View")
        titleLabel.text = TextsAsset.Preferences.connection

        setupFillLayoutView()
        layoutView.scrollView.bounces = false
        layoutView.stackView.spacing = 8
        layoutView.stackView.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 12))

        if #available(iOS 15.1, *) {
            layoutView.stackView.addArrangedSubviews([
                networkWhiteListRow,
                connectionModeViewV2,
                makeConnectionSecureView(type: .killSwitch),
                connectedDNSView,
                makeConnectionSecureView(type: .allowLan),
                circumventCensorshipView
            ])
        } else {
            layoutView.stackView.addArrangedSubviews([
                networkWhiteListRow,
                connectionModeViewV2,
                connectedDNSView,
                circumventCensorshipView
            ])
        }
        bindViews()
    }

    override func viewWillLayoutSubviews() {
        layoutView.setup()
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupTheme(isDark: isDark)
        }).disposed(by: disposeBag)

        networkWhiteListRow.rx.anyGesture(.tap()).skip(1).subscribe(onNext: { _ in
            self.locationManagerViewModel.requestLocationPermission {
                self.openNetworkWhiteList()
            }
        }).disposed(by: disposeBag)

        locationManagerViewModel.shouldPresentLocationPopUp.subscribe {
            self.router.routeTo(to: RouteID.locationPermission(delegate: self.locationManagerViewModel, denied: $0),
                                from: self)
        }.disposed(by: disposeBag)

        viewModel.isCircumventCensorshipEnabled.subscribe {
            self.circumventCensorshipView.switchButton.setStatus($0)
        }.disposed(by: disposeBag)

        viewModel.shouldShowCustomDNSOption.subscribe {
            self.connectedDNSView.isHidden = !$0
        }.disposed(by: disposeBag)
    }

    // MARK: - UI Helper

    private func makeConnectionSecureView(type: ConnectionSecure) -> ConnectionSecureView {
        let view = ConnectionSecureView(isDarkMode: viewModel.isDarkMode)
        view.titleLabel.text = type.title
        view.subTitleLabel.text = type.description
        switch type {
        case .killSwitch:
            view.setImage(UIImage(named: GeneralViewType.killSwitch.asset))
            view.hideShowExplainIcon(true)
            view.switchButton.setStatus(viewModel.getKillSwitchStatus())
            view.connectionSecureViewSwitchAcction = { [weak self] in
                self?.viewModel.updateChangeKillSwitchStatus()
            }
        case .allowLan:
            view.setImage(UIImage(named: GeneralViewType.allowLan.asset))
            view.explainHandler = { [weak self] in
                if let url = URL(string: FeatureExplainer.allowLan.getUrl()) {
                    self?.openLink(url: url)
                }
            }
            view.switchButton.setStatus(viewModel.getAllowLanStatus())
            view.connectionSecureViewSwitchAcction = { [weak self] in
                self?.viewModel.updateChangeAllowLanStatus()
            }
        case .autoSecure:
            view.setImage(UIImage(named: GeneralViewType.autoConnection.asset))
            view.switchButton.setStatus(viewModel.getAutoSecureNetworkStatus())
            view.connectionSecureViewSwitchAcction = { [weak self] in
                self?.viewModel.updateAutoSecureNetworkStatus()
            }
        case .circumventCensorship:
            view.setImage(UIImage(named: ImagesAsset.circumventCensorship))
            view.explainHandler = { [weak self] in
                if let url = URL(string: FeatureExplainer.circumventCensorship.getUrl()) {
                    self?.openLink(url: url)
                }
            }
            view.connectionSecureViewSwitchAcction = { [weak self] in
                self?.viewModel.updateCircumventCensorshipStatus(status: view.switchButton.status)
            }
        default:
            break
        }
        return view
    }

    func openNetworkWhiteList() {
        router.routeTo(to: RouteID.networkSecurity, from: self)
    }

    func setupTheme(isDark: Bool) {
        super.setupViews(isDark: isDark)
    }
}

class EmptyCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - extensions

extension ConnectionViewController: ConnectionModeViewDelegate {
    func connectionModeViewExplain() {
        if let url = URL(string: FeatureExplainer.connectionModes.getUrl()) {
            openLink(url: url)
        }
    }

    func connectionModeViewDidSwitch(_: ConnectionModeView, value _: Bool) {}

    func connectionModeViewDidChangeMode(_ option: ConnectionModeType) {
        viewModel.updateConnectionMode(value: option)
    }

    func connectionModeViewDidChangeProtocol(_ value: String) {
        viewModel.updateProtocol(value: value)
        let listPort = viewModel.getPorts()
        if let portFirst = listPort.first {
            viewModel.updatePort(value: portFirst)
        }
        connectionModeViewV2.updateListPortOption(listPort)
    }

    func connectionModeViewDidChangePort(_ value: String) {
        viewModel.updatePort(value: value)
    }
}

extension ConnectionViewController: ConnectedDNSViewDelegate {
    func connectedDNSViewSaveValue(_ value: String) {
        showLoading()
        viewModel.saveConnectedDNSValue(value: value) { [weak self] isValid in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.endLoading()
                if isValid {
                    self.connectedDNSView.updateConnectedDNSValue(value: value)
                } else {
                    let cancelAction = UIAlertAction(title: TextsAsset.cancel, style: .default) { _ in
                        DispatchQueue.main.async {
                            self.connectedDNSView.cancelUpdateValue()
                        }
                    }
                    AlertManager().showAlert(title: TextsAsset.Connection.connectedDNSInvalidAlertTitle, message: TextsAsset.Connection.connectedDNSInvalidAlertBody, buttonText: TextsAsset.okay, actions: [cancelAction])
                }
            }
        }
    }

    func connectedDNSViewDidChangeType(_ option: ConnectedDNSType) {
        viewModel.updateConnectedDNS(type: option)
    }

    func connectedDNSViewExplain() {
        if let url = URL(string: FeatureExplainer.connectedDNS.getUrl()) {
            openLink(url: url)
        }
    }

    func connectedDNSViewDidStartEditing() {
        layoutView.scrollView.scrollToView(view: connectedDNSView, animated: true)
    }
}

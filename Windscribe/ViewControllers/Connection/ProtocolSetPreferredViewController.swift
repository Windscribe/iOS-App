//
//  ProtocolSetPreferredViewController.swift
//  Windscribe
//
//  Created by Thomas on 29/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import Swinject

class ProtocolSetPreferredViewController: WSNavigationViewController {
    var router: ProtocolSwitchViewRouter!
    // MARK: - PROPERTIES
    var viewModel: ProtocolSetPreferredViewModelV2!
    weak var delegate: ProtocolSwitchVCDelegate?
    var type: ProtocolViewType?
    var protocolName: String = "" {
        didSet {
            if viewModel.type != .fail {
                headerLabel.text = "Set “\(protocolName)” as preferred protocol?"
            }
        }
    }

    // MARK: - UI ELEMENTs
    private lazy var topImage: UIImageView = {
        let vw = UIImageView()
        vw.image = UIImage(named: ImagesAsset.windscribeWarning)
        vw.contentMode = .scaleAspectFit
        vw.setDimensions(height: 86, width: 86)
        return vw
    }()

    private lazy var headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.font = UIFont.bold(size: 21)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var subHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = viewModel.getSubHeader()
        lbl.alpha = 0.5
        lbl.font = UIFont.text(size: 16)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton()
        return btn
    }()

    private lazy var setPreferredButton: WSButton = {
        let btn = WSButton(type: .hightlight,
                           size: .large,
                           text: "Set as Preferred".localize(),
                           isDarkMode: viewModel.isDarkMode)
        return btn
    }()

    private lazy var sendDebugLogButton: WSButton = {
        let btn = WSButton(type: .normal,
                           size: .large,
                           text: TextsAsset.AutoModeFailedToConnectPopup.sendDebugLog,
                           isDarkMode: viewModel.isDarkMode)
        return btn
    }()

    // MARK: - CONFIGs

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
        self.viewModel.type = type ?? .connected
    }

    private func bindViews() {
        cancelButton.rx.tap.bind {
            AutomaticMode.shared.resetFailCounts()
            super.backButtonTapped()
            self.delegate?.disconnectFromFailOver()
        }.disposed(by: disposeBag)

        setPreferredButton.rx.tap.bind {
            self.setPreferredAction()
        }.disposed(by: disposeBag)

        sendDebugLogButton.rx.tap.bind {
            self.viewModel.submitLog()
        }.disposed(by: disposeBag)
        viewModel.submitLogState.observe(on: MainScheduler.instance).bind { data in
            switch data {
            case .initial:
                self.endLoading()
            case .sending:
                self.showLoading()
            case .sent:
                self.endLoading()
                self.showSendDebugLogCompleted()
            case .failed:
                self.endLoading()
            }
        }.disposed(by: disposeBag)

        viewModel.isDarkMode.subscribe {
            self.setupViews(isDark: $0)
            self.headerLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.subHeaderLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)

            self.topImage.updateTheme(isDark: $0)
            let attribute = NSAttributedString(
                string: "Cancel".localize(),
                attributes: [NSAttributedString.Key.font: UIFont.bold(size: 16),
                             NSAttributedString.Key.foregroundColor: ThemeUtils.primaryTextColor50(isDarkMode: $0)]
            )
            self.cancelButton.setAttributedTitle(attribute, for: .normal)
        }.disposed(by: disposeBag)
    }

    private func setup() {
        DispatchQueue.main.async { [weak self] in
            self?.setupCloseButton()
            self?.setupFillLayoutView()
            self?.layoutView.stackView.spacing = 16
            if let s = self {
                s.layoutView.stackView.addArrangedSubviews([
                    s.topImage,
                    s.headerLabel,
                    s.subHeaderLabel,
                    s.setPreferredButton,
                    s.sendDebugLogButton,
                    s.cancelButton
                ])
                s.layoutView.stackView.setCustomSpacing(32, after: s.topImage)
                s.layoutView.stackView.setCustomSpacing(s.viewModel.type == .fail ? 64 : 32, after: s.subHeaderLabel)
                s.layoutView.stackView.setCustomSpacing(32, after: s.setPreferredButton)
                s.layoutView.stackView.setCustomSpacing(32, after: s.sendDebugLogButton)
            }

            self?.layoutView.stackView.setPadding(UIEdgeInsets(top: 54, left: 48, bottom: 16, right: 48))
            if self?.viewModel.type == .fail {
                self?.headerLabel.text = self?.viewModel.failHeaderString
                self?.sendDebugLogButton.isHidden = false
                self?.setPreferredButton.isHidden = true
            } else {
                self?.sendDebugLogButton.isHidden = true
                self?.setPreferredButton.isHidden = false
            }
        }
    }

    // MARK: - Actions

    private func showSendDebugLogCompleted() {
        router.routeTo(to: RouteID.sendDebugLogCompleted(delegate: self), from: self)
    }

    private func setPreferredAction() {
        guard let network = viewModel.securedNetwork.getCurrentNetwork() else { return }
        guard let portsArray = viewModel.localDatabase.getPorts(protocolType: protocolName) else { return }
        let defaultPort = portsArray[0]
        viewModel.localDatabase.updateWifiNetwork(network: network,
                                        properties: [
                                            Fields.WifiNetwork.preferredProtocol: protocolName,
                                            Fields.WifiNetwork.preferredPort: defaultPort,
                                            Fields.WifiNetwork.preferredProtocolStatus: true
                                        ])
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}

extension ProtocolSetPreferredViewController: SendDebugLogCompletedVCDelegate {
    func sendDebugLogCompletedVCCanceled() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}

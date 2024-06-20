//
//  ProtocolSwitchViewController.swift
//  Windscribe
//
//  Created by Thomas on 22/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol ProtocolSwitchVCDelegate: AnyObject {
    func protocolSwitchVCCountdownCompleted()
    func disconnectFromFailOver()
}

class ProtocolSwitchViewController: WSNavigationViewController {
    var viewModel: ProtocolSwitchViewModelType!
    var connectionManager: ConnectionManagerV2!
    var router: ProtocolSwitchViewRouter!
    // MARK: - Properties
    var type: ProtocolFallbacksType = .change

    weak var delegate: ProtocolSwitchVCDelegate?
    // MARK: - UI Elements
    private lazy var topImage: UIImageView = {
        let vw = UIImageView()
        vw.image = UIImage(named: type.getIconAsset())
        vw.contentMode = .scaleAspectFit
        vw.setDimensions(height: 86, width: 86)
        return vw
    }()

    private lazy var headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = type.getHeader()
        lbl.font = UIFont.bold(size: 21)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var subHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = type.getDescription()
        lbl.alpha = 0.5
        lbl.font = UIFont.text(size: 16)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var protocolStack: UIStackView = {
        let vw = UIStackView(arrangedSubviews: [
        ])
        vw.axis = .vertical
        vw.spacing = 16
        return vw
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton()
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
    }

    private func setup() {
        if !VPNManager.shared.isConnected() {
            VPNManager.shared.isFromProtocolFailover = true
            VPNManager.shared.isFromProtocolChange = false
        } else {
            VPNManager.shared.isFromProtocolChange = true
            VPNManager.shared.isFromProtocolFailover = false
        }
        setupFillLayoutView()
        layoutView.stackView.spacing = 16
        layoutView.stackView.addArrangedSubviews([
            topImage,
            headerLabel,
            subHeaderLabel,
            protocolStack,
            cancelButton
        ])
        createProtocolView()
        layoutView.stackView.setPadding(UIEdgeInsets(top: 54, left: 48, bottom: 16, right: 48))
        layoutView.stackView.setCustomSpacing(32, after: topImage)
        layoutView.stackView.setCustomSpacing(32, after: subHeaderLabel)
        layoutView.stackView.setCustomSpacing(32, after: protocolStack)
        setupCloseButton()
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            setupViews(isDark: isDark)
            topImage.updateTheme(isDark: isDark)
            headerLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            subHeaderLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDark)
            let attribute = NSAttributedString(
                string: "Cancel".localize(),
                attributes: [NSAttributedString.Key.font: UIFont.bold(size: 16),
                             NSAttributedString.Key.foregroundColor: ThemeUtils.primaryTextColor50(isDarkMode: isDark)]
            )
            cancelButton.setAttributedTitle(attribute, for: .normal)
        }).disposed(by: disposeBag)

        cancelButton.rx.tap.bind {
            if VPNManager.shared.isConnected() {
                self.backButtonTapped()
            } else {
                AutomaticMode.shared.resetFailCounts()
                self.delegate?.disconnectFromFailOver()
                self.backButtonTapped()
            }
        }.disposed(by: disposeBag)
    }

    private func createProtocolView() {
        protocolStack.removeAllArrangedSubviews()
        connectionManager.loadProtocols { [self] displayConnection in
            for dt in displayConnection {
                var protocolDescription: String
                switch dt.protocolPort.protocolName {
                case iKEv2:
                    protocolDescription = "IKEv2 is an IPsec based tunneling protocol.".localize()
                case udp:
                    protocolDescription = "Balanced speed and security.".localize()
                case tcp:
                    protocolDescription = "Use it if OpenVPN UDP fails.".localize()
                case wsTunnel:
                    protocolDescription = "Wraps your HTTPS traffic with web sockets.".localize()
                case stealth:
                    protocolDescription = "Disguises your traffic as HTTPS traffic with TLS".localize()
                case wireGuard:
                    protocolDescription = "Extremely simple yet fast and modern VPN protocol.".localize()
                default:
                    protocolDescription = "One line description.".localize()
                }

                let vw = ProtocolView(type: dt.viewType,
                                      protocolName: dt.protocolPort.protocolName,
                                      portName: dt.protocolPort.portName, description: protocolDescription,
                                      isDarkMode: viewModel.isDarkMode,
                                      delegate: self, fallbackType: self.type)

                protocolStack.addArrangedSubview(vw)
            }
        }
    }
}

extension ProtocolSwitchViewController: ProtocolViewDelegate {
    func protocolViewDidSelect(_ protocolView: ProtocolView) {
        protocolView.invalidateTimer()
        if protocolView.type == .connected {
            router.routeTo(to: RouteID.protocolSetPreferred(type: protocolView.type, delegate: nil, protocolName: protocolView.protocolName), from: self)
        } else if protocolView.type != .fail {
            connectionManager.onUserSelectProtocol(proto: (protocolView.protocolName, protocolView.portName))
            delegate?.protocolSwitchVCCountdownCompleted()

            backButtonTapped()
        }
    }

    func protocolViewNextUpCompleteCoundown(_ protocolView: ProtocolView) {
        protocolView.invalidateTimer()
        if !VPNManager.shared.isConnected() {
            connectionManager.onUserSelectProtocol(proto: (protocolView.protocolName, protocolView.portName))
            delegate?.protocolSwitchVCCountdownCompleted()

        }
        backButtonTapped()
    }
}

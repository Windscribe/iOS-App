//
//  ConnectionStateInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 21/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol ConnectionStateInfoViewModelType {
    var statusSubject: BehaviorSubject<ConnectionState?> { get }
    var isCircumventCensorshipEnabled: BehaviorSubject<Bool> { get }
    var refreshProtocolSubject: BehaviorSubject<ProtocolPort?> { get }
    var isCustomConfigSelected: Bool { get }
    var isAntiCensorshipEnabled: Bool { get }
    var isConnecting: Bool { get }
    var isConnected: Bool { get }
}

class ConnectionStateInfoViewModel: ConnectionStateInfoViewModelType {
    let statusSubject = BehaviorSubject<ConnectionState?>(value: nil)
    let isCircumventCensorshipEnabled = BehaviorSubject<Bool>(value: false)
    let refreshProtocolSubject: BehaviorSubject<ProtocolPort?>

    let disposeBag = DisposeBag()

    let locationsManager: LocationsManagerType
    let vpnManager: VPNManager
    let preferences: Preferences
    let protocolManager: ProtocolManagerType

    init(vpnManager: VPNManager, locationsManager: LocationsManagerType,
         preferences: Preferences, protocolManager: ProtocolManagerType) {
        self.locationsManager = locationsManager
        self.preferences = preferences
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        refreshProtocolSubject = protocolManager.currentProtocolSubject

        vpnManager.getStatus().subscribe(onNext: { state in
            self.statusSubject.onNext(ConnectionState.state(from: state))
        }).disposed(by: disposeBag)
        preferences.getCircumventCensorshipEnabled().subscribe { [weak self] data in
            self?.isCircumventCensorshipEnabled.onNext(data)
        }.disposed(by: disposeBag)
    }

    var isCustomConfigSelected: Bool {
        locationsManager.isCustomConfigSelected()
    }

    var isAntiCensorshipEnabled: Bool {
        preferences.isCircumventCensorshipEnabled()
    }

    var isConnecting: Bool {
        vpnManager.isConnecting()
    }

    var isConnected: Bool {
        vpnManager.isConnected()
    }
}

protocol ConnectionStateInfoViewDelegate: AnyObject {
    func protocolPortTapped()
}

class ConnectionStateInfoView: UIView {
    let disposeBag = DisposeBag()

    weak var delegate: ConnectionStateInfoViewDelegate?

    var pillView = UIView()
    var pillLabel = UILabel()
    var connectingImageView = UIImageView()
    var actionButton = UIButton()
    var protocolLabel = UILabel()
    var portLabel = UILabel()
    var preferredIcon = UIImageView()
    var circunventIcon = UIImageView()
    var actionIcon = UIImageView()
    var stackView = UIStackView()
    private var images: [UIImage] = []

    var viewModel: ConnectionStateInfoViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    private func bindViewModel() {
        viewModel.statusSubject.subscribe { [weak self] state in
            guard let self = self, let state = state else { return }
            DispatchQueue.main.async {
                self.updateConnectionInfo(state)
            }
        }.disposed(by: disposeBag)

        viewModel.isCircumventCensorshipEnabled.subscribe { [weak self] isVisible in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.circunventIcon.isHidden = !isVisible
            }
        }.disposed(by: disposeBag)

        viewModel.refreshProtocolSubject.subscribe { [weak self] protoPort in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshProtocol(from: nil, with: protoPort, isNetworkCellularWhileConnecting: false)
            }
        }.disposed(by: disposeBag)

        actionButton.rx.tap.bind { [weak self] in
            guard let self = self,
                  viewModel.isConnected else { return }
            self.delegate?.protocolPortTapped()
        }.disposed(by: disposeBag)

        actionIcon.isHidden = !viewModel.isConnected
    }

    private func updateConnectionInfo(_ state: ConnectionState) {
        pillLabel.text = state.statusText
        pillLabel.isHidden = [.testing, .connecting, .automaticFailed].contains(state)
        pillLabel.textColor = state.statusColor

        connectingImageView.isHidden = ![.connecting, .testing].contains(state)
        connectingImageView.tintColor = state.statusColor

        if connectingImageView.isHidden && connectingImageView.isAnimating {
            connectingImageView.stopAnimating()
        } else if !connectingImageView.isHidden && !connectingImageView.isAnimating {
            connectingImageView.startAnimating()
        }

        pillView.backgroundColor = state.statusViewColor
        pillView.layer.borderColor = state.statusViewColor.cgColor

        var isEnabled = false
        if [.connected, .connecting].contains(state) {
            isEnabled = !viewModel.isCustomConfigSelected
        } else {
            isEnabled = ![.disconnected, .disconnecting].contains(state)
        }
        actionIcon.isHidden = !(state == .connected && isEnabled)
        actionButton.isUserInteractionEnabled = (state == .connected && isEnabled)
        actionIcon.setImageColor(color: state.statusColor)

        protocolLabel.textColor = state.statusColor
        portLabel.textColor = state.statusColor

        preferredIcon.image = UIImage(named: state.preferredProtocolBadge)
        preferredIcon.setImageColor(color: state.statusColor)
        setCircumventCensorshipBadge(color: state.statusColor.withAlphaComponent(state.statusAlpha))
    }

    private func setCircumventCensorshipBadge(color: UIColor? = nil) {
        circunventIcon.isHidden = !viewModel.isAntiCensorshipEnabled
        if let color = color {
            circunventIcon.tintColor = color
        }
        circunventIcon.layoutIfNeeded()
        layoutIfNeeded()
    }

    func showNoInternetConnection() {
        pillLabel.isHidden = true
        connectingImageView.image = UIImage(named: ImagesAsset.noInternet)
        connectingImageView.isHidden = false
    }

    func updateProtoPort(_ value: ProtocolPort) {
        protocolLabel.text = value.protocolName
        portLabel.text = value.portName
    }

    func refreshProtocol(from network: WifiNetwork?, with protoPort: ProtocolPort?, isNetworkCellularWhileConnecting: Bool) {
        if network?.isInvalidated == true {
            return
        }
        guard let protoPort = protoPort else {
            preferredIcon.isHidden = true
            return
        }
        updateProtoPort(protoPort)

        if !(network?.SSID.isEmpty ?? true), viewModel.isConnected || viewModel.isConnecting {
            if let status = network?.preferredProtocolStatus, status, protoPort.protocolName == network?.preferredProtocol, protoPort.portName == network?.preferredPort {
                preferredIcon.isHidden = false
            } else {
                guard !isNetworkCellularWhileConnecting else {
                    // This means the network is temporarly cellular while connecting to VPN
                    return
                }
                preferredIcon.isHidden = true
            }
            return
        }
        if WifiManager.shared.selectedPreferredProtocolStatus ?? false, WifiManager.shared.selectedPreferredProtocol == protoPort.protocolName, WifiManager.shared.selectedPreferredPort == protoPort.portName {
            preferredIcon.isHidden = false
        } else {
            preferredIcon.isHidden = true
        }
    }

    private func addViews() {
        pillView.backgroundColor = .whiteWithOpacity(opacity: 0.1)
        pillView.layer.cornerRadius = 11
        pillView.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.1).cgColor
        pillView.layer.borderWidth = 1
        pillView.layer.masksToBounds = true
        pillView.clipsToBounds = true

        pillLabel.textAlignment = .center
        pillLabel.adjustsFontSizeToFitWidth = true
        pillLabel.font = UIFont.bold(size: 12)
        pillLabel.text = TextsAsset.Status.off
        pillLabel.textColor = UIColor.white

        protocolLabel.textAlignment = .center
        protocolLabel.adjustsFontSizeToFitWidth = true
        protocolLabel.font = UIFont.bold(size: 12)
        protocolLabel.textColor = UIColor.white
        protocolLabel.text = WifiManager.shared.getConnectedNetwork()?.protocolType ?? TextsAsset.wireGuard

        portLabel.textAlignment = .center
        portLabel.adjustsFontSizeToFitWidth = true
        portLabel.font = UIFont.regular(size: 12)
        portLabel.textColor = UIColor.white
        portLabel.text = WifiManager.shared.getConnectedNetwork()?.port ?? "443"

        actionIcon.image = UIImage(named: ImagesAsset.serverWhiteRightArrow)
        actionIcon.layer.opacity = 0.4
        actionIcon.setImageColor(color: .white)
        actionIcon.contentMode = .scaleAspectFit

        preferredIcon.isHidden = false
        preferredIcon.contentMode = .scaleAspectFit

        circunventIcon.isHidden = false
        circunventIcon.image = UIImage(named: ImagesAsset.circumventCensorship)?.withRenderingMode(.alwaysTemplate)
        circunventIcon.setImageColor(color: .whiteWithOpacity(opacity: 0.4))
        circunventIcon.contentMode = .scaleAspectFit

        connectingImageView.tintColor = .white
        connectingImageView.animationDuration = 0.8
        connectingImageView.animationRepeatCount = 0
        connectingImageView.animationImages = [ImagesAsset.connectindDots1,
                                               ImagesAsset.connectindDots2,
                                               ImagesAsset.connectindDots3,
                                               ImagesAsset.connectindDots4].compactMap {
            UIImage(named: $0)?.withRenderingMode(.alwaysTemplate)
        }

        stackView.addArrangedSubviews([pillView, circunventIcon, protocolLabel, portLabel, preferredIcon, actionIcon])
        stackView.spacing = 8

        pillView.addSubview(pillLabel)
        pillView.addSubview(connectingImageView)

        addSubview(stackView)
        addSubview(actionButton)
    }

    private func setLayout() {
        pillView.translatesAutoresizingMaskIntoConstraints = false
        pillLabel.translatesAutoresizingMaskIntoConstraints = false
        connectingImageView.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        protocolLabel.translatesAutoresizingMaskIntoConstraints = false
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        preferredIcon.translatesAutoresizingMaskIntoConstraints = false
        circunventIcon.translatesAutoresizingMaskIntoConstraints = false
        actionIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackView
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),

            // pillView
            pillView.widthAnchor.constraint(equalToConstant: 39),

            // pillLabel
            pillLabel.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            pillLabel.centerXAnchor.constraint(equalTo: pillView.centerXAnchor),

            // connectingImageView
            connectingImageView.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            connectingImageView.centerXAnchor.constraint(equalTo: pillView.centerXAnchor),
            connectingImageView.widthAnchor.constraint(equalToConstant: 19),
            connectingImageView.heightAnchor.constraint(equalToConstant: 5),

            // actionButton
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.widthAnchor.constraint(equalTo: self.widthAnchor),
            actionButton.heightAnchor.constraint(equalTo: self.heightAnchor),

            // preferredIcon
            preferredIcon.widthAnchor.constraint(equalToConstant: 8),
            preferredIcon.heightAnchor.constraint(equalToConstant: 8),

            // circunventIcon
            circunventIcon.widthAnchor.constraint(equalToConstant: 12),
            circunventIcon.heightAnchor.constraint(equalToConstant: 12),

            // actionIcon
            actionIcon.widthAnchor.constraint(equalToConstant: 12),
            actionIcon.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
}

extension MainViewController: ConnectionStateInfoViewDelegate {
    func protocolPortTapped() {
        openConnectionChangeDialog()
    }
}

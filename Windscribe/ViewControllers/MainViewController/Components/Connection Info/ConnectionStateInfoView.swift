//
//  ConnectionStateInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 21/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Combine

protocol ConnectionStateInfoViewModelType {
    var statusSubject: CurrentValueSubject<ConnectionState?, Never> { get }
    var hasNetwork: CurrentValueSubject<Bool, Never> { get }
    var isCircumventCensorshipEnabled: CurrentValueSubject<Bool, Never> { get }
    var refreshProtocolSubject: CurrentValueSubject<ProtocolPort?, Never> { get }
    var isCustomConfigSelected: Bool { get }
    var isAntiCensorshipEnabled: Bool { get }
    var isConnecting: Bool { get }
    var isConnected: Bool { get }
}

class ConnectionStateInfoViewModel: ConnectionStateInfoViewModelType {
    let statusSubject = CurrentValueSubject<ConnectionState?, Never>(nil)
    let isCircumventCensorshipEnabled = CurrentValueSubject<Bool, Never>(false)
    let hasNetwork = CurrentValueSubject<Bool, Never>(false)
    let refreshProtocolSubject = CurrentValueSubject<ProtocolPort?, Never>(ProtocolPort(DefaultValues.protocol, DefaultValues.port))

    private var cancellables = Set<AnyCancellable>()

    let locationsManager: LocationsManager
    let vpnStateRepository: VPNStateRepository
    let preferences: Preferences
    let protocolManager: ProtocolManagerType
    let connectivityManager: ConnectivityManager
    let wifiManager: WifiManager

    init(vpnStateRepository: VPNStateRepository,
         locationsManager: LocationsManager,
         preferences: Preferences,
         protocolManager: ProtocolManagerType,
         connectivityManager: ConnectivityManager,
         wifiManager: WifiManager) {
        self.locationsManager = locationsManager
        self.preferences = preferences
        self.vpnStateRepository = vpnStateRepository
        self.protocolManager = protocolManager
        self.connectivityManager = connectivityManager
        self.wifiManager = wifiManager
        vpnStateRepository.getStatus()
            .sink { [weak self] state in
                self?.statusSubject.send(ConnectionState.state(from: state))
            }
            .store(in: &cancellables)

        preferences.getCircumventCensorshipEnabled()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.isCircumventCensorshipEnabled.send(data)
            }
            .store(in: &cancellables)

        protocolManager.currentProtocolSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.refreshProtocolSubject.send(data)
            }.store(in: &cancellables)

        connectivityManager.network
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appNetwork in
                guard let self = self else { return }
                hasNetwork.send(appNetwork.status == .connected)
            }
            .store(in: &cancellables)
    }

    var isCustomConfigSelected: Bool {
        locationsManager.isCustomConfigSelected()
    }

    var isAntiCensorshipEnabled: Bool {
        preferences.isCircumventCensorshipEnabled()
    }

    var isConnecting: Bool {
        vpnStateRepository.isConnecting()
    }

    var isConnected: Bool {
        vpnStateRepository.isConnected()
    }
}

protocol ConnectionStateInfoViewDelegate: AnyObject {
    func protocolPortTapped()
}

class ConnectionStateInfoView: UIView {
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: ConnectionStateInfoViewDelegate?

    var pillView = UIView()
    var pillLabel = UILabel()
    var connectingImageView = UIImageView()
    var actionButton = UIButton()
    var protocolLabel = UILabel()
    var portLabel = UILabel()
    var preferredIcon = UIImageView()
    var circunventIcon = UIImageView()
    var noConnectionIcon = UIImageView()
    var actionIcon = UIImageView()
    var stackView = UIStackView()
    private var images: [UIImage] = []
    private let wifiManager: WifiManager

    var viewModel: ConnectionStateInfoViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(wifiManager: WifiManager) {
        self.wifiManager = wifiManager
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    private func bindViewModel() {
        viewModel.statusSubject.combineLatest(viewModel.hasNetwork)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, hasNetwork  in
                guard let self = self, let state = state else { return }
                updateConnectionInfo(state, hasNetwork)
            }
            .store(in: &cancellables)

        viewModel.isCircumventCensorshipEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isVisible in
                guard let self = self else { return }
                self.circunventIcon.isHidden = !isVisible
            }
            .store(in: &cancellables)

        viewModel.refreshProtocolSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] protoPort in
                guard let self = self else { return }
                self.refreshProtocol(from: nil, with: protoPort, isNetworkCellularWhileConnecting: false)
            }
            .store(in: &cancellables)

        actionButton.tap
            .sink { [weak self] _ in
                guard let self = self,
                      viewModel.isConnected else { return }
                self.delegate?.protocolPortTapped()
            }
            .store(in: &cancellables)

        actionIcon.isHidden = !viewModel.isConnected
    }

    private func updateConnectionInfo(_ state: ConnectionState, _ hasNetwork: Bool) {
        pillLabel.text = state.statusText
        pillLabel.textColor = state.statusColor

        connectingImageView.tintColor = state.statusColor

        if !hasNetwork && state != .connecting {
            showNoInternetConnection()
        } else {
            noConnectionIcon.isHidden = true
            connectingImageView.isHidden = ![.connecting, .testing].contains(state)
            pillLabel.isHidden = [.testing, .connecting, .automaticFailed].contains(state)
        }

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
        let currentValue = viewModel.isCircumventCensorshipEnabled.value
        circunventIcon.isHidden = !currentValue
        if let color = color {
            circunventIcon.tintColor = color
        }
        circunventIcon.layoutIfNeeded()
        layoutIfNeeded()
    }

    private func showNoInternetConnection() {
        pillLabel.isHidden = true
        connectingImageView.isHidden = true
        noConnectionIcon.isHidden = false
    }

    func updateProtoPort(_ value: ProtocolPort) {
        protocolLabel.text = value.protocolName
        portLabel.text = value.portName
    }

    func refreshProtocol(from network: WifiNetworkModel?, with protoPort: ProtocolPort?, isNetworkCellularWhileConnecting: Bool) {
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
        if wifiManager.selectedPreferredProtocolStatus ?? false, wifiManager.selectedPreferredProtocol == protoPort.protocolName, wifiManager.selectedPreferredPort == protoPort.portName {
            preferredIcon.isHidden = false
        } else {
            preferredIcon.isHidden = true
        }
    }

    private func addViews() {
        pillView.backgroundColor = .whiteWithOpacity(opacity: 0.1)
        pillView.layer.cornerRadius = Self.pillSize.height / 2.0
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
        protocolLabel.text = wifiManager.getConnectedNetwork()?.protocolType ?? VPNProtocolType.wireGuard.displayName

        portLabel.textAlignment = .center
        portLabel.adjustsFontSizeToFitWidth = true
        portLabel.font = UIFont.regular(size: 12)
        portLabel.textColor = UIColor.white
        portLabel.text = wifiManager.getConnectedNetwork()?.port ?? "443"

        actionIcon.image = UIImage(named: ImagesAsset.serverWhiteRightArrow)
        actionIcon.layer.opacity = 0.4
        actionIcon.setImageColor(color: .white)
        actionIcon.contentMode = .scaleAspectFit

        preferredIcon.isHidden = true
        preferredIcon.contentMode = .scaleAspectFit

        circunventIcon.isHidden = true
        circunventIcon.image = UIImage(named: ImagesAsset.circumventCensorship)?.withRenderingMode(.alwaysTemplate)
        circunventIcon.setImageColor(color: .whiteWithOpacity(opacity: 0.4))
        circunventIcon.contentMode = .scaleAspectFit

        connectingImageView.tintColor = .white
        connectingImageView.animationDuration = 0.8
        connectingImageView.animationRepeatCount = 0
        connectingImageView.isHidden = true
        connectingImageView.animationImages = [ImagesAsset.connectindDots1,
                                               ImagesAsset.connectindDots2,
                                               ImagesAsset.connectindDots3,
                                               ImagesAsset.connectindDots4].compactMap {
            UIImage(named: $0)?.withRenderingMode(.alwaysTemplate)
        }

        noConnectionIcon.image = UIImage(named: ImagesAsset.noInternet)
        noConnectionIcon.isHidden = true

        stackView.addArrangedSubviews([pillView, circunventIcon, protocolLabel, portLabel, preferredIcon, actionIcon])
        stackView.alignment = .center
        stackView.spacing = 8

        pillView.addSubview(pillLabel)
        pillView.addSubview(connectingImageView)
        pillView.addSubview(noConnectionIcon)

        addSubview(stackView)
        addSubview(actionButton)
    }

    private static let pillSize = CGSizeMake(39.0, 19.0)

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
        noConnectionIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackView
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),

            // pillView
            pillView.heightAnchor.constraint(equalToConstant: Self.pillSize.height),
            pillView.widthAnchor.constraint(equalToConstant: Self.pillSize.width),

            // pillLabel
            pillLabel.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            pillLabel.centerXAnchor.constraint(equalTo: pillView.centerXAnchor),

            // connectingImageView
            connectingImageView.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            connectingImageView.centerXAnchor.constraint(equalTo: pillView.centerXAnchor),
            connectingImageView.widthAnchor.constraint(equalToConstant: 19),
            connectingImageView.heightAnchor.constraint(equalToConstant: 5),

            // noConnectionIcon
            noConnectionIcon.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            noConnectionIcon.centerXAnchor.constraint(equalTo: pillView.centerXAnchor),
            noConnectionIcon.widthAnchor.constraint(equalToConstant: 16),
            noConnectionIcon.heightAnchor.constraint(equalToConstant: 12),

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

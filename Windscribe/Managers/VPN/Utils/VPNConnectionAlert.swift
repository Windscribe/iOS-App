//
//  VPNConnectionAlert.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol VPNConnectionAlertDelegate: AnyObject {
    func didSelectProtocol(protocolPort: ProtocolPort)
    func didTapDisconnect()
    func tapToCancel()
}

enum VPNActionType {
    case connect
    case disconnect
    case cancel
    case error(String)
}

class VPNConnectionAlert: UIViewController {
    weak var delegate: VPNConnectionAlertDelegate?
    private var actionType: VPNActionType = .connect
    private let protocols = [ProtocolPort(TextsAsset.wireGuard, "443"), ProtocolPort(TextsAsset.iKEv2, "500"), ProtocolPort(udp, "443"), ProtocolPort(tcp, "443"), ProtocolPort(stealth, "443"), ProtocolPort(wsTunnel, "443")]
    private var selectedProtocol = ProtocolPort(TextsAsset.wireGuard, "443")

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    private let protocolPicker = UIPickerView()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 24
        button.backgroundColor = .seaGreen
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.midnight
        view.layer.cornerRadius = 10
        setupSubviews()

        protocolPicker.delegate = self
        protocolPicker.dataSource = self
    }

    private func setupSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(protocolPicker)
        view.addSubview(progressLabel)
        view.addSubview(actionButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        protocolPicker.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            protocolPicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            protocolPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            protocolPicker.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

            progressLabel.topAnchor.constraint(equalTo: protocolPicker.bottomAnchor, constant: 16),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            actionButton.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 16),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            actionButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            actionButton.heightAnchor.constraint(equalToConstant: 48.0),
        ])
    }

    func configure(for actionType: VPNActionType) {
        self.actionType = actionType

        switch actionType {
        case .connect:
            titleLabel.text = "Let's connect"
            actionButton.setTitle("Connect", for: .normal)
            protocolPicker.isHidden = false
            actionButton.isEnabled = true
            actionButton.alpha = 1.0
        case .disconnect:
            titleLabel.text = "Let's disconnect"
            actionButton.setTitle("Disconnect", for: .normal)
            protocolPicker.isHidden = true
            actionButton.isEnabled = true
            actionButton.alpha = 1.0
        case let .error(error):
            titleLabel.text = error
            actionButton.setTitle("Okay", for: .normal)
            protocolPicker.isHidden = true
            actionButton.isEnabled = true
            actionButton.alpha = 1.0
        case .cancel:
            titleLabel.text = "Connection is in porgress"
            actionButton.setTitle("Cancel", for: .normal)
            protocolPicker.isHidden = true
            actionButton.isEnabled = true
            actionButton.alpha = 1.0
        }
    }

    @objc private func actionButtonTapped() {
        switch actionType {
        case .connect:
            delegate?.didSelectProtocol(protocolPort: selectedProtocol)
            progressLabel.text = "Connecting..."
        case .disconnect:
            delegate?.didTapDisconnect()
            progressLabel.text = "Disconnecting..."
        case .error:
            dismissAlert()
        case .cancel:
            progressLabel.text = "Cancelling"
            delegate?.tapToCancel()
        }
    }

    func updateProgress(message: String) {
        progressLabel.text = message
    }

    func dismissAlert() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource

extension VPNConnectionAlert: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in _: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        return protocols.count
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        return protocols[row].protocolName
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        selectedProtocol = protocols[row]
    }
}

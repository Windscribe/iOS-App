//
//  VPNConnectionAlert.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol VPNConnectionAlertDelegate: AnyObject {
    func didSelectProtocol(_ protocolName: String)
    func didTapDisconnect()
}

enum VPNActionType {
    case connect
    case disconnect
}

class VPNConnectionAlert: UIViewController {
    weak var delegate: VPNConnectionAlertDelegate?
    private var actionType: VPNActionType = .connect
    private let protocols = [TextsAsset.wireGuard, TextsAsset.iKEv2, udp, tcp, stealth, wsTunnel]
    private var selectedProtocol = TextsAsset.wireGuard

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()

    private let protocolPicker = UIPickerView()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.4, alpha: 1.0)
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

            progressLabel.topAnchor.constraint(equalTo: protocolPicker.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            actionButton.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 16),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }

    func configure(for actionType: VPNActionType) {
        self.actionType = actionType

        switch actionType {
        case .connect:
            titleLabel.text = "Let's connect"
            actionButton.setTitle("Connect", for: .normal)
            protocolPicker.isHidden = false
        case .disconnect:
            titleLabel.text = "Lets' disconnect"
            actionButton.setTitle("Disconnect", for: .normal)
            protocolPicker.isHidden = true
        }
    }

    @objc private func actionButtonTapped() {
        switch actionType {
        case .connect:
            delegate?.didSelectProtocol(selectedProtocol)
            progressLabel.text = "Connecting..."
        case .disconnect:
            delegate?.didTapDisconnect()
            progressLabel.text = "Disconnecting..."
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
        return protocols[row]
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        selectedProtocol = protocols[row]
    }
}

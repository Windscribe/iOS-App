//
//  MainViewController+UIAutoModeSelectorView.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController {
    func addAutoModeSelectorViews() {
        autoModeSelectorView = UIView()
        autoModeSelectorView.isHidden = true
        autoModeSelectorView.frame = CGRect(x: 16, y: view.frame.maxY + 100,
                                            width: view.frame.width - 32, height: 44)
        autoModeSelectorView.layer.cornerRadius = 24.5
        autoModeSelectorView.layer.opacity = 0.96
        autoModeSelectorView.backgroundColor = UIColor.autoModeSelectorYellow
        view.addSubview(autoModeSelectorView)

        autoModeSelectorInfoIconView = UIImageView(image: UIImage(named: ImagesAsset.autoModeSelectorInfoIcon))
        autoModeSelectorInfoIconView.layer.opacity = 0.4
        autoModeSelectorView.addSubview(autoModeSelectorInfoIconView)

        autoModeInfoLabel = UILabel()
        autoModeInfoLabel.text = TextsAsset.autoModeSelectorInfo
        autoModeInfoLabel.textColor = UIColor.failedConnectionYellow
        autoModeInfoLabel.font = UIFont.text(size: 14)
        autoModeSelectorView.addSubview(autoModeInfoLabel)

        autoModeSelectorCounterLabel = UILabel()
        autoModeSelectorCounterLabel.text = "20"
        autoModeSelectorCounterLabel.textColor = UIColor.failedConnectionYellow
        autoModeSelectorCounterLabel.font = UIFont.bold(size: 14)
        autoModeSelectorView.addSubview(autoModeSelectorCounterLabel)

        autoModeSelectorIkev2Button = LargeTapAreaImageButton()
        autoModeSelectorIkev2Button.addTarget(self, action: #selector(autoModeProtocolButtonTapped), for: .touchUpInside)
        autoModeSelectorIkev2Button.setTitle(iKEv2, for: .normal)
        autoModeSelectorIkev2Button.setTitleColor(UIColor.failedConnectionYellow, for: .normal)
        autoModeSelectorIkev2Button.layer.opacity = 0.4
        autoModeSelectorIkev2Button.titleLabel?.font = UIFont.bold(size: 14)
        autoModeSelectorView.addSubview(autoModeSelectorIkev2Button)

        autoModeSelectorUDPButton = LargeTapAreaImageButton()
        autoModeSelectorUDPButton.addTarget(self, action: #selector(autoModeProtocolButtonTapped), for: .touchUpInside)
        autoModeSelectorUDPButton.setTitle(udp, for: .normal)
        autoModeSelectorUDPButton.setTitleColor(UIColor.failedConnectionYellow, for: .normal)
        autoModeSelectorUDPButton.layer.opacity = 0.4
        autoModeSelectorUDPButton.titleLabel?.font = UIFont.bold(size: 14)
        autoModeSelectorView.addSubview(autoModeSelectorUDPButton)

        autoModeSelectorTCPButton = LargeTapAreaImageButton()
        autoModeSelectorTCPButton.addTarget(self, action: #selector(autoModeProtocolButtonTapped), for: .touchUpInside)
        autoModeSelectorTCPButton.setTitle(tcp, for: .normal)
        autoModeSelectorTCPButton.setTitleColor(UIColor.failedConnectionYellow, for: .normal)
        autoModeSelectorTCPButton.layer.opacity = 0.4
        autoModeSelectorTCPButton.titleLabel?.font = UIFont.bold(size: 14)
        autoModeSelectorView.addSubview(autoModeSelectorTCPButton)

        autoModeSelectorOverlayView = UIView()
        autoModeSelectorOverlayView.frame = CGRect(x: autoModeSelectorIkev2Button.frame.minX - 5, y: autoModeSelectorIkev2Button.frame.minY - 5, width: 60, height: 34)
        autoModeSelectorOverlayView.isUserInteractionEnabled = false
        autoModeSelectorOverlayView.layer.cornerRadius = 17.5
        autoModeSelectorOverlayView.layer.opacity = 0.20
        autoModeSelectorOverlayView.backgroundColor = UIColor.failedConnectionYellow
        autoModeSelectorView.addSubview(autoModeSelectorOverlayView)

        addAutoLayoutConstraints()
    }

    func addAutoLayoutConstraintsForAutoModeSelectorViews() {
        autoModeSelectorInfoIconView.translatesAutoresizingMaskIntoConstraints = false
        autoModeInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        autoModeSelectorCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        autoModeSelectorIkev2Button.translatesAutoresizingMaskIntoConstraints = false
        autoModeSelectorUDPButton.translatesAutoresizingMaskIntoConstraints = false
        autoModeSelectorTCPButton.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: autoModeSelectorInfoIconView as Any, attribute: .centerY, relatedBy: .equal, toItem: autoModeSelectorView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoModeSelectorInfoIconView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: autoModeSelectorInfoIconView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: autoModeSelectorInfoIconView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: autoModeInfoLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: autoModeSelectorView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoModeInfoLabel as Any, attribute: .left, relatedBy: .equal, toItem: autoModeSelectorInfoIconView, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: autoModeInfoLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 18)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: autoModeSelectorCounterLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: autoModeSelectorView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoModeSelectorCounterLabel as Any, attribute: .left, relatedBy: .equal, toItem: autoModeInfoLabel, attribute: .right, multiplier: 1.0, constant: 4),
            NSLayoutConstraint(item: autoModeSelectorCounterLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 18)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: autoModeSelectorIkev2Button as Any, attribute: .centerY, relatedBy: .equal, toItem: autoModeSelectorView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoModeSelectorIkev2Button as Any, attribute: .left, relatedBy: .greaterThanOrEqual, toItem: autoModeSelectorCounterLabel, attribute: .right, multiplier: 1.0, constant: 10),
            NSLayoutConstraint(item: autoModeSelectorIkev2Button as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 18)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: autoModeSelectorUDPButton as Any, attribute: .centerY, relatedBy: .equal, toItem: autoModeSelectorView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoModeSelectorUDPButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 18)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: autoModeSelectorTCPButton as Any, attribute: .centerY, relatedBy: .equal, toItem: autoModeSelectorView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: autoModeSelectorTCPButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -36),
            NSLayoutConstraint(item: autoModeSelectorTCPButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 18)
        ])
        if UIDevice.current.isIphone5orLess() {
            view.addConstraints([
                NSLayoutConstraint(item: autoModeSelectorTCPButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -12),
                NSLayoutConstraint(item: autoModeSelectorUDPButton as Any, attribute: .right, relatedBy: .equal, toItem: autoModeSelectorTCPButton, attribute: .left, multiplier: 1.0, constant: -12),
                NSLayoutConstraint(item: autoModeSelectorIkev2Button as Any, attribute: .right, relatedBy: .equal, toItem: autoModeSelectorUDPButton, attribute: .left, multiplier: 1.0, constant: -12)
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: autoModeSelectorTCPButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -36),
                NSLayoutConstraint(item: autoModeSelectorUDPButton as Any, attribute: .right, relatedBy: .equal, toItem: autoModeSelectorTCPButton, attribute: .left, multiplier: 1.0, constant: -32),
                NSLayoutConstraint(item: autoModeSelectorIkev2Button as Any, attribute: .right, relatedBy: .equal, toItem: autoModeSelectorUDPButton, attribute: .left, multiplier: 1.0, constant: -32)
            ])
        }
    }

    @objc private func autoModeProtocolButtonTapped(sender: UIButton) {
        switch sender {
        case autoModeSelectorIkev2Button:
            setAutoModeSelectorOverlayFocus(button: sender, selectedProtocol: iKEv2)
        case autoModeSelectorUDPButton:
            setAutoModeSelectorOverlayFocus(button: sender, selectedProtocol: udp)
        case autoModeSelectorTCPButton:
            setAutoModeSelectorOverlayFocus(button: sender, selectedProtocol: tcp)
        default:
            return
        }
    }

    private func setAutoModeSelectorOverlayFocus(button: UIButton, selectedProtocol: String) {
        UIView.animate(withDuration: 0.35) {
            self.autoModeSelectorOverlayView.center.x = button.center.x
            self.autoModeSelectorOverlayView.center.y = button.center.y
            self.selectedNextProtocol = selectedProtocol
        }
    }
}

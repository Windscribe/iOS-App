//
//  SetPreferredProtocolPopupViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-10.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension SetPreferredProtocolPopupViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        backgroundView.layer.opacity = 0.95
        view.addSubview(backgroundView)

        imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.attention)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)

        titleLabel = UILabel()
        titleLabel.font = UIFont.bold(size: 26)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        networkNameLabel = UILabel()
        networkNameLabel.font = UIFont.text(size: 16)
        networkNameLabel.adjustsFontSizeToFitWidth = true
        networkNameLabel.textColor = UIColor.white
        networkNameLabel.textAlignment = .center
        view.addSubview(networkNameLabel)

        descriptionLabel = UILabel()
        descriptionLabel.text = TextsAsset.SetPreferredProtocolPopup.message
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.text(size: 16)
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.textColor = UIColor.white
        view.addSubview(descriptionLabel)

        actionButton = UIButton(type: .system)
        actionButton.setTitle(TextsAsset.SetPreferredProtocolPopup.action, for: .normal)
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        view.addSubview(actionButton)

        cancelButton = UIButton()
        cancelButton.setTitle(TextsAsset.SetPreferredProtocolPopup.cancel, for: .normal)
        cancelButton.layer.opacity = 0.5
        cancelButton.titleLabel?.font = UIFont.bold(size: 16)
        cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        view.addSubview(cancelButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        networkNameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: backgroundView as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
        ])
        if UIScreen.hasTopNotch {
            view.addConstraints([
                NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1.0, constant: 175),
            ])
        } else if UIScreen.main.nativeBounds.height <= 1136 {
            view.addConstraints([
                NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1.0, constant: 90),
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1.0, constant: 120),
            ])
        }
        view.addConstraints([
            NSLayoutConstraint(item: imageView as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 86),
            NSLayoutConstraint(item: imageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 86),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: titleLabel as Any, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 45),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -45),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 28),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: networkNameLabel as Any, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: networkNameLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 75),
            NSLayoutConstraint(item: networkNameLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -75),
            NSLayoutConstraint(item: networkNameLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 28),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .top, relatedBy: .equal, toItem: networkNameLabel, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 55),
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -55),
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 51),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: actionButton as Any, attribute: .top, relatedBy: .equal, toItem: descriptionLabel, attribute: .bottom, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: actionButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 68),
            NSLayoutConstraint(item: actionButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -68),
            NSLayoutConstraint(item: actionButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: cancelButton as Any, attribute: .top, relatedBy: .equal, toItem: actionButton, attribute: .bottom, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 68),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -68),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
    }
}

//
//  PushNotificationViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension PushNotificationViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        backgroundView.layer.opacity = 0.95
        view.addSubview(backgroundView)

        imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.pushNotifications)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)

        titleLabel = UILabel()
        titleLabel.text = TextsAsset.PushNotifications.title
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        descriptionLabel = UILabel()
        descriptionLabel.text = TextsAsset.PushNotifications.description
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.text(size: 16)
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.textColor = UIColor.white
        view.addSubview(descriptionLabel)

        actionButton = UIButton(type: .system)
        actionButton.setTitle(TextsAsset.PushNotifications.action, for: .normal)
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        view.addSubview(actionButton)

        cancelButton = UIButton()
        cancelButton.setTitle(TextsAsset.TrustedNetworkPopup.cancel, for: .normal)
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
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let imageViewTopDistance = UIScreen.hasTopNotch ? 175.0 : (UIScreen.main.nativeBounds.height <= 1136 ? 90.0 : 120.0)

        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // imageView
            imageView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: imageViewTopDistance),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 86),
            imageView.heightAnchor.constraint(equalToConstant: 86),

            // titleLabel
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 75),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -75),
            titleLabel.heightAnchor.constraint(equalToConstant: 32),

            // descriptionLabel
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 55),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -55),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 51),

            // actionButton
            actionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            actionButton.heightAnchor.constraint(equalToConstant: 48),

            // cancelButton
            cancelButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 32),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            cancelButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}

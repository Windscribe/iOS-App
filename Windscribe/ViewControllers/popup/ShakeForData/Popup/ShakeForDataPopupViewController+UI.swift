//
//  ShakeForDataPopupViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-12.
//  Copyright © 2019 Windscribe. All rights reserved.
//
import UIKit

extension ShakeForDataPopupViewController {
    func addViews() {
        self.view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        backgroundView.layer.opacity = 0.95
        self.view.addSubview(backgroundView)

        imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.shakeForDataIcon)
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)

        titleLabel = UILabel()
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)

        descriptionLabel = UILabel()
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.text(size: 16)
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.textColor = UIColor.white
        self.view.addSubview(descriptionLabel)

        actionButton = UIButton(type: .system)
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        self.view.addSubview(actionButton)

        cancelButton = UIButton()
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.layer.opacity = 0.5
        cancelButton.titleLabel?.font = UIFont.bold(size: 16)
        cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.view.addSubview(cancelButton)

        divider = UIView()
        divider.layer.opacity = 0.15
        divider.backgroundColor = UIColor.white
        self.view.addSubview(divider)

        viewLeaderboardButton  = UIButton()
        viewLeaderboardButton.layer.opacity = 0.5
        viewLeaderboardButton.titleLabel?.font = UIFont.bold(size: 16)
        viewLeaderboardButton.titleLabel?.adjustsFontSizeToFitWidth = true
        viewLeaderboardButton.setTitleColor(UIColor.white, for: .normal)
        self.view.addSubview(viewLeaderboardButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false
        viewLeaderboardButton.translatesAutoresizingMaskIntoConstraints = false

        let isSmallScreen = UIScreen.main.nativeBounds.height <= 1136
        let imageViewTopDistance =  UIScreen.hasTopNotch ? 175.0 : ( isSmallScreen ? 50.0 : 100.0)

        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // imageView
            imageView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: imageViewTopDistance),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: isSmallScreen ? 80.0 : 120.0),
            imageView.heightAnchor.constraint(equalToConstant: isSmallScreen ? 80.0 : 120.0),

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
            cancelButton.heightAnchor.constraint(equalToConstant: 48),

            // divider
            divider.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            divider.heightAnchor.constraint(equalToConstant: 2),

            // viewLeaderboardButton
            viewLeaderboardButton.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            viewLeaderboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            viewLeaderboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            viewLeaderboardButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

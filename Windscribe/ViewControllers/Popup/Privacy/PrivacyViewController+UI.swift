//
//  PrivacyViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-09-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension PrivacyViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        backgroundView.layer.opacity = 0.95
        view.addSubview(backgroundView)

        descriptionLabel = UILabel()
        descriptionLabel.text = TextsAsset.PrivacyView.description
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.font = UIFont.text(size: fontSize)
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.adjustsFontSizeToFitWidth = true

        descriptionLabel.textColor = UIColor.white
        view.addSubview(descriptionLabel)

        actionButton = UIButton(type: .system)
        actionButton.setTitle(TextsAsset.PrivacyView.action, for: .normal)
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        view.addSubview(actionButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

            // descriptionLabel
            descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.isSmallScreen ? 60 : 120),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),

            // actionButton
            actionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

//
//  InfoPromptViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-13.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension InfoPromptViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        view.addSubview(backgroundView)

        iconView = UIImageView()
        iconView.image = UIImage(named: ImagesAsset.promptInfo)
        view.addSubview(iconView)

        infoLabel = UILabel()
        infoLabel.font = UIFont.text(size: 16)
        infoLabel.textColor = UIColor.white
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        view.addSubview(infoLabel)

        actionButton = UIButton(type: .system)
        actionButton.setTitle(title, for: .normal)
        actionButton.setTitleColor(UIColor.white, for: .normal)
        actionButton.backgroundColor = UIColor.buttonGray
        actionButton.layer.cornerRadius = 28
        view.addSubview(actionButton)

        cancelButton = UIButton(type: .system)
        cancelButton.setTitle(TextsAsset.back, for: .normal)
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.backgroundColor = UIColor.buttonGray
        cancelButton.layer.cornerRadius = 28
        view.addSubview(cancelButton)
    }

    func addConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // descriptionLabel
            iconView.bottomAnchor.constraint(equalTo: infoLabel.topAnchor, constant: -24),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            // infoLabel
            infoLabel.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 24),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // actionButton
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            actionButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: 55),

            // cancelButton
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
}

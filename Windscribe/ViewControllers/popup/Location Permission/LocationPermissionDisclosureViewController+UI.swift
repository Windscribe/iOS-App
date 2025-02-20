//
//  LocationPermissionInfoViewController+UI.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-09-14.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit

extension LocationPermissionInfoViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        view.addSubview(backgroundView)

        infoIcon = UIImageView()
        infoIcon.image = UIImage(named: ImagesAsset.promptInfo)
        view.addSubview(infoIcon)

        titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.bold(size: 26)
        titleLabel.text = TextsAsset.Permission.disclaimer
        view.addSubview(titleLabel)

        descriptionLabel = UILabel()
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = UIColor.white
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.text(size: 16)
        descriptionLabel.text = TextsAsset.Permission.disclosureDescription
        view.addSubview(descriptionLabel)

        actionButton = UIButton(type: .system)
        actionButton.setTitle(denied ? TextsAsset.Permission.openSettings : TextsAsset.Permission.grantPermission, for: .normal)
        actionButton.titleLabel?.font = UIFont.bold(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        view.addSubview(actionButton)

        cancelButton = UIButton()
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.setTitle(TextsAsset.cancel, for: .normal)
        cancelButton.layer.opacity = 0.5
        cancelButton.titleLabel?.font = UIFont.bold(size: 16)
        cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(
                item: backgroundView as Any,
                attribute: .top,
                relatedBy: .equal,
                toItem: view,
                attribute: .top,
                multiplier: 1.0,
                constant: topSpace
            ),
            NSLayoutConstraint(
                item: backgroundView as Any,
                attribute: .left,
                relatedBy: .equal,
                toItem: view,
                attribute: .left,
                multiplier: 1.0,
                constant: 0
            ),
            NSLayoutConstraint(
                item: backgroundView as Any,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: view,
                attribute: .bottom,
                multiplier: 1.0,
                constant: 0
            ),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        let titleLabelConstraints = [
            NSLayoutConstraint(
                item: titleLabel as Any,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: descriptionLabel,
                attribute: .top,
                multiplier: 1.0,
                constant: -16
            ),
            NSLayoutConstraint(
                item: titleLabel as Any,
                attribute: .left,
                relatedBy: .equal,
                toItem: view,
                attribute: .left,
                multiplier: 1.0,
                constant: 0
            ),
            NSLayoutConstraint(
                item: titleLabel as Any,
                attribute: .right,
                relatedBy: .equal,
                toItem: view,
                attribute: .right,
                multiplier: 1.0,
                constant: 0
            )
        ]

        let infoIconConstraints = [
            NSLayoutConstraint(
                item: infoIcon as Any,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: titleLabel,
                attribute: .top,
                multiplier: 1.0,
                constant: -16
            ),
            NSLayoutConstraint(
                item: infoIcon as Any,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: view,
                attribute: .centerX,
                multiplier: 1.0,
                constant: 0
            ),
            NSLayoutConstraint(
                item: infoIcon as Any,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .width,
                multiplier: 1.0,
                constant: 48
            ),
            NSLayoutConstraint(
                item: infoIcon as Any,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .height,
                multiplier: 1.0,
                constant: 48
            )
        ]

        let descriptionLabelConstraints = [
            NSLayoutConstraint(
                item: descriptionLabel as Any,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: view,
                attribute: .centerY,
                multiplier: 1.0,
                constant: topSpace
            ),
            NSLayoutConstraint(
                item: descriptionLabel as Any,
                attribute: .left,
                relatedBy: .equal,
                toItem: view,
                attribute: .left,
                multiplier: 1.0,
                constant: 16
            ),
            NSLayoutConstraint(
                item: descriptionLabel as Any,
                attribute: .right,
                relatedBy: .equal,
                toItem: view,
                attribute: .right,
                multiplier: 1.0,
                constant: -16
            )
        ]

        let cancelButtonConstraints = [
            NSLayoutConstraint(
                item: cancelButton as Any,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: view,
                attribute: .bottom,
                multiplier: 1.0,
                constant: -16
            ),
            NSLayoutConstraint(
                item: cancelButton as Any,
                attribute: .left,
                relatedBy: .equal,
                toItem: view,
                attribute: .left,
                multiplier: 1.0,
                constant: 16
            ),
            NSLayoutConstraint(
                item: cancelButton as Any,
                attribute: .right,
                relatedBy: .equal,
                toItem: view,
                attribute: .right,
                multiplier: 1.0,
                constant: -16
            )
        ]

        let actionButtonConstraints = [
            NSLayoutConstraint(
                item: actionButton as Any,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: cancelButton,
                attribute: .top,
                multiplier: 1.0,
                constant: -16
            ),
            NSLayoutConstraint(
                item: actionButton as Any,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .height,
                multiplier: 1.0,
                constant: 48
            ),
            NSLayoutConstraint(
                item: actionButton as Any,
                attribute: .left,
                relatedBy: .equal,
                toItem: view,
                attribute: .left,
                multiplier: 1.0,
                constant: 16
            ),
            NSLayoutConstraint(
                item: actionButton as Any,
                attribute: .right,
                relatedBy: .equal,
                toItem: view,
                attribute: .right,
                multiplier: 1.0,
                constant: -16
            )
        ]

        NSLayoutConstraint.activate(infoIconConstraints)
        NSLayoutConstraint.activate(titleLabelConstraints)
        NSLayoutConstraint.activate(descriptionLabelConstraints)
        NSLayoutConstraint.activate(cancelButtonConstraints)
        NSLayoutConstraint.activate(actionButtonConstraints)
    }
}

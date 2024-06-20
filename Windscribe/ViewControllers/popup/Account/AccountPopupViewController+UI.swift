//
//  AccountPopupViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-20.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension AccountPopupViewController {

    func addViews() {
        self.view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        backgroundView.layer.opacity = 0.95
        self.view.addSubview(backgroundView)

        imageView = UIImageView()
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
        actionButton.setTitle(TextsAsset.OutOfData.action, for: .normal)
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        self.view.addSubview(actionButton)

        cancelButton = UIButton()
        cancelButton.setTitle(TextsAsset.OutOfData.cancel, for: .normal)
        cancelButton.layer.opacity = 0.5
        cancelButton.titleLabel?.font = UIFont.bold(size: 16)
        cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        self.view.addSubview(cancelButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addConstraints([
            NSLayoutConstraint(item: backgroundView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: self.backgroundView, attribute: .top, multiplier: 1.0, constant: 175)
                ])
        } else if UIScreen.main.nativeBounds.height <= 1136 {
            self.view.addConstraints([
                NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: self.backgroundView, attribute: .top, multiplier: 1.0, constant: 90)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: self.backgroundView, attribute: .top, multiplier: 1.0, constant: 120)
                ])
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: imageView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imageView as Any, attribute: .width, relatedBy: .equal, toItem: nil ,attribute: .width, multiplier: 1.0, constant: 150),
            NSLayoutConstraint(item: imageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 150)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: titleLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.imageView, attribute: .bottom, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 75),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -75),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.titleLabel, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 55),
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -55),
            NSLayoutConstraint(item: descriptionLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 51)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: actionButton as Any, attribute: .top, relatedBy: .equal, toItem: self.descriptionLabel, attribute: .bottom, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: actionButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 68),
            NSLayoutConstraint(item: actionButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -68),
            NSLayoutConstraint(item: actionButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: cancelButton as Any, attribute: .top, relatedBy: .equal, toItem: self.actionButton, attribute: .bottom, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 68),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -68),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20)
            ])
    }

}

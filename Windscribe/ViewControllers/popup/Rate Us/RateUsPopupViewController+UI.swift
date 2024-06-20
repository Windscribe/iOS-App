//
//  RateUsPopupViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension RateUsPopupViewController {

    func addViews() {
        self.view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        backgroundView.layer.opacity = 0.95
        self.view.addSubview(backgroundView)

        imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.rateUs)
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)

        titleLabel = UILabel()
        titleLabel.text = TextsAsset.RateUs.title
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)

        descriptionLabel = UILabel()
        descriptionLabel.text = TextsAsset.RateUs.description
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.text(size: 16)
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.textColor = UIColor.white
        self.view.addSubview(descriptionLabel)

        actionButton = UIButton(type: .system)
        actionButton.setTitle(TextsAsset.RateUs.action, for: .normal)
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.backgroundColor = UIColor.seaGreen
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.clipsToBounds = true
        self.view.addSubview(actionButton)

        cancelButton = ImageButton()
        cancelButton.setImage(UIImage(named: ImagesAsset.closeIcon), for: .normal)
        cancelButton.layer.opacity = 1.0
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        self.view.addSubview(cancelButton)

        maybeLaterButton = UIButton(type: .system)
        maybeLaterButton.setTitle(TextsAsset.RateUs.maybeLater, for: .normal)
        maybeLaterButton.titleLabel?.font = UIFont.bold(size: 16)
        maybeLaterButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        maybeLaterButton.setTitleColor(UIColor.white, for: .normal)
        maybeLaterButton.layer.opacity = 0.5
        self.view.addSubview(maybeLaterButton)

        goAwayButton = UIButton(type: .system)
        goAwayButton.setTitle(TextsAsset.RateUs.goAway, for: .normal)
        goAwayButton.titleLabel?.font = UIFont.bold(size: 16)
        goAwayButton.addTarget(self, action: #selector(goAwayButtonTapped), for: .touchUpInside)
        goAwayButton.setTitleColor(UIColor.white, for: .normal)
        goAwayButton.layer.opacity = 0.5
        self.view.addSubview(goAwayButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        maybeLaterButton.translatesAutoresizingMaskIntoConstraints = false
        goAwayButton.translatesAutoresizingMaskIntoConstraints = false

        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                NSLayoutConstraint(item: cancelButton as Any, attribute: .top, relatedBy: .equal, toItem: self.backgroundView, attribute: .top, multiplier: 1.0, constant: 75)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: cancelButton as Any, attribute: .top, relatedBy: .equal, toItem: self.backgroundView, attribute: .top, multiplier: 1.0, constant: 32)
                ])
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: cancelButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: cancelButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 32)
            ])
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
            NSLayoutConstraint(item: imageView as Any, attribute: .width, relatedBy: .equal, toItem: nil ,attribute: .width, multiplier: 1.0, constant: 86),
            NSLayoutConstraint(item: imageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 86)
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
            NSLayoutConstraint(item: maybeLaterButton as Any, attribute: .top, relatedBy: .equal, toItem: self.actionButton, attribute: .bottom, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: maybeLaterButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: maybeLaterButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: maybeLaterButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: goAwayButton as Any, attribute: .top, relatedBy: .equal, toItem: self.maybeLaterButton, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: goAwayButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: goAwayButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: goAwayButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20)
            ])
    }

}

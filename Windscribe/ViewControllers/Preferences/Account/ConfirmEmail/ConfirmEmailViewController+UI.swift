//
//  ConfirmEmailViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2020-02-03.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension ConfirmEmailViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundView.roundCorners(corners: [.topLeft, .topRight], radius: 24)
    }

    func addViews() {
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.lightMidnight
        view.addSubview(backgroundView)

        iconView = UIImageView()
        iconView.image = UIImage(named: ImagesAsset.confirmEmail)
        view.addSubview(iconView)

        titleLabel = UILabel()
        titleLabel.text = TextsAsset.EmailView.confirmEmail
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.textColor = UIColor.white
        view.addSubview(titleLabel)

        infoLabel = UILabel()

        if let session = viewModel.sessionManager.session, session.isUserPro {
            infoLabel.text = TextsAsset.EmailView.infoPro
        } else {
            infoLabel.text = TextsAsset.EmailView.info
        }
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.text(size: 16)
        infoLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        view.addSubview(infoLabel)

        resendButton = UIButton(type: .system)
        resendButton.layer.borderColor = UIColor.white.cgColor
        resendButton.layer.borderWidth = 2
        resendButton.layer.cornerRadius = 24
        resendButton.clipsToBounds = true
        resendButton.layer.opacity = 0.5
        resendButton.setTitle(TextsAsset.EmailView.resendEmail, for: .normal)
        resendButton.setTitleColor(UIColor.white, for: .normal)
        resendButton.titleLabel?.font = UIFont.text(size: 16)
        resendButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(resendButton)

        changeButton = UIButton(type: .system)
        changeButton.layer.borderColor = UIColor.white.cgColor
        changeButton.layer.borderWidth = 2
        changeButton.layer.cornerRadius = 24
        changeButton.clipsToBounds = true
        changeButton.layer.opacity = 0.5
        changeButton.setTitle(TextsAsset.EmailView.changeEmail, for: .normal)
        changeButton.setTitleColor(UIColor.white, for: .normal)
        changeButton.titleLabel?.font = UIFont.text(size: 16)
        changeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(changeButton)

        closeButton = UIButton(type: .system)
        closeButton.setTitle(TextsAsset.EmailView.close, for: .normal)
        closeButton.setTitleColor(UIColor.whiteWithOpacity(opacity: 0.5), for: .normal)
        closeButton.titleLabel?.font = UIFont.bold(size: 16)
        view.addSubview(closeButton)
    }

    func addAutolayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        resendButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: backgroundView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: UIScreen.main.bounds.height / 3),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: iconView as Any, attribute: .bottom, relatedBy: .equal, toItem: titleLabel, attribute: .top, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: iconView as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: iconView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 68),
            NSLayoutConstraint(item: iconView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 68)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: titleLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: infoLabel, attribute: .top, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: infoLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: resendButton, attribute: .top, multiplier: 1.0, constant: -32),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 48),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -48)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: resendButton as Any, attribute: .bottom, relatedBy: .equal, toItem: changeButton, attribute: .top, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: resendButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: resendButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: resendButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: changeButton as Any, attribute: .bottom, relatedBy: .equal, toItem: closeButton, attribute: .top, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: changeButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: changeButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: changeButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: closeButton as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -40),
            NSLayoutConstraint(item: closeButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: closeButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: closeButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20)
        ])
    }
}

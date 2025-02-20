//
//  GhostAccountViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-20.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension GhostAccountViewController {
    func addViews() {
        infoLabel = UILabel()
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.text(size: 16)
        view.addSubview(infoLabel)

        signUpButton = UIButton(type: .system)
        signUpButton.layer.cornerRadius = 26
        signUpButton.clipsToBounds = true
        signUpButton.backgroundColor = UIColor.seaGreen
        signUpButton.titleLabel?.font = UIFont.text(size: 16)
        view.addSubview(signUpButton)

        loginButton = UIButton(type: .system)
        loginButton.layer.opacity = 0.5
        loginButton.titleLabel?.font = UIFont.bold(size: 16)
        view.addSubview(loginButton)
    }

    func addAutoLayoutConstraints() {
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: infoLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 50),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -50)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: signUpButton as Any, attribute: .bottom, relatedBy: .equal, toItem: loginButton, attribute: .top, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: signUpButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50),
            NSLayoutConstraint(item: signUpButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 28),
            NSLayoutConstraint(item: signUpButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -28)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: loginButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: loginButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: loginButton as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -24)
        ])
    }
}

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
        infoLabel.textColor = UIColor.white
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.text(size: 16)
        self.view.addSubview(infoLabel)

        signUpButton = UIButton(type: .system)
        signUpButton.layer.cornerRadius = 26
        signUpButton.clipsToBounds = true
        signUpButton.backgroundColor = UIColor.seaGreen
        signUpButton.setTitleColor(UIColor.midnight, for: .normal)
        signUpButton.titleLabel?.font = UIFont.text(size: 16)
        self.view.addSubview(signUpButton)

        loginButton = UIButton(type: .system)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.layer.opacity = 0.5
        loginButton.titleLabel?.font = UIFont.bold(size: 16)
        self.view.addSubview(loginButton)
    }

    func addAutoLayoutConstraints() {
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false

         self.view.addConstraints([
             NSLayoutConstraint(item: infoLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0),
             NSLayoutConstraint(item: infoLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 50),
             NSLayoutConstraint(item: infoLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -50)
        ])
         self.view.addConstraints([
             NSLayoutConstraint(item: signUpButton as Any, attribute: .bottom, relatedBy: .equal, toItem: self.loginButton, attribute: .top, multiplier: 1.0, constant: -24),
             NSLayoutConstraint(item: signUpButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50),
             NSLayoutConstraint(item: signUpButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 28),
             NSLayoutConstraint(item: signUpButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -28)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: loginButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: loginButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: loginButton as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -24)
        ])
    }

}

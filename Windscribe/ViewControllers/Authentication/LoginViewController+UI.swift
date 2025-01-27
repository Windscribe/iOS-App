//
//  LoginViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-09.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension LoginViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if UIDevice.current.isIphone5orLess() {
            scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height - 200)
        } else {
            scrollView.isScrollEnabled = false
        }
    }

    func addViews() {
        addNotificationObservers()
        if UIScreen.hasTopNotch {
            scrollView = UIScrollView(frame: CGRect(x: 0, y: 115, width: view.frame.width, height: view.frame.height))
        } else {
            scrollView = UIScrollView(frame: CGRect(x: 0, y: 75, width: view.frame.width, height: view.frame.height))
        }
        view.addSubview(scrollView)

        usernameLabel = UILabel()
        usernameLabel.font = UIFont.bold(size: 16)
        usernameLabel.textAlignment = .left
        scrollView.addSubview(usernameLabel)

        usernameTextfield = LoginTextField(isDarkMode: viewModel.isDarkMode)
        scrollView.addSubview(usernameTextfield)

        usernameInfoIconImageView = UIImageView()
        usernameInfoIconImageView.isHidden = true
        usernameInfoIconImageView.image = UIImage(named: ImagesAsset.failExIcon)
        scrollView.addSubview(usernameInfoIconImageView)

        passwordLabel = UILabel()
        passwordLabel.font = UIFont.bold(size: 16)
        passwordLabel.textAlignment = .left
        scrollView.addSubview(passwordLabel)

        passwordTextfield = PasswordTextField(isDarkMode: viewModel.isDarkMode)
        passwordTextfield.isSecureTextEntry = true
        scrollView.addSubview(passwordTextfield)

        infoLabel = UILabel()
        infoLabel.font = UIFont.text(size: 12)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.failRed
        scrollView.addSubview(infoLabel)

        passwordInfoIconImageView = UIImageView()
        passwordInfoIconImageView.isHidden = true
        passwordInfoIconImageView.image = UIImage(named: ImagesAsset.failExIcon)
        scrollView.addSubview(passwordInfoIconImageView)

        twoFactorCodeTextfield = LoginTextField(isDarkMode: viewModel.isDarkMode)
        twoFactorCodeTextfield.keyboardType = .numberPad
        scrollView.addSubview(twoFactorCodeTextfield)

        twoFactorInfoLabel = UILabel()
        twoFactorInfoLabel.font = UIFont.text(size: 12)
        twoFactorInfoLabel.textAlignment = .left
        twoFactorInfoLabel.layer.opacity = 0.5
        scrollView.addSubview(twoFactorInfoLabel)

        twoFactorCodeButton = UIButton(type: .system)
        twoFactorCodeButton.titleLabel?.font = UIFont.text(size: 16)
        twoFactorCodeButton.layer.opacity = 0.5
        scrollView.addSubview(twoFactorCodeButton)

        forgotPasswordButton = UIButton(type: .system)
        forgotPasswordButton.titleLabel?.font = UIFont.text(size: 16)
        forgotPasswordButton.layer.opacity = 0.5
        scrollView.addSubview(forgotPasswordButton)

        continueButton = UIButton(type: .system)
        continueButton.layer.cornerRadius = 26
        continueButton.clipsToBounds = true
        scrollView.addSubview(continueButton)

        loadingView = UIActivityIndicatorView(style: .gray)
        scrollView.addSubview(loadingView)
    }

    func addAutoLayoutConstraints() {
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameTextfield.translatesAutoresizingMaskIntoConstraints = false
        passwordTextfield.translatesAutoresizingMaskIntoConstraints = false
        twoFactorCodeButton.translatesAutoresizingMaskIntoConstraints = false
        twoFactorCodeTextfield.translatesAutoresizingMaskIntoConstraints = false
        twoFactorInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameInfoIconImageView.translatesAutoresizingMaskIntoConstraints = false
        passwordInfoIconImageView.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: usernameLabel as Any, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: usernameLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: usernameTextfield as Any, attribute: .top, relatedBy: .equal, toItem: usernameLabel, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: usernameTextfield as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: usernameTextfield as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: usernameTextfield as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: usernameInfoIconImageView as Any, attribute: .bottom, relatedBy: .equal, toItem: usernameTextfield, attribute: .top, multiplier: 1.0, constant: -8),
            NSLayoutConstraint(item: usernameInfoIconImageView as Any, attribute: .right, relatedBy: .equal, toItem: usernameTextfield, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: usernameInfoIconImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: usernameInfoIconImageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: passwordLabel as Any, attribute: .top, relatedBy: .equal, toItem: usernameTextfield, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: passwordLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: passwordTextfield as Any, attribute: .top, relatedBy: .equal, toItem: passwordLabel, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: passwordTextfield as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: passwordTextfield as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: passwordTextfield as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: twoFactorCodeButton as Any, attribute: .top, relatedBy: .equal, toItem: passwordTextfield, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: twoFactorCodeButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: twoFactorCodeButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        twoFactorCodeTextfieldHeightConstraint = NSLayoutConstraint(item: twoFactorCodeTextfield as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 0)
        view.addConstraints([
            NSLayoutConstraint(item: twoFactorCodeTextfield as Any, attribute: .top, relatedBy: .equal, toItem: twoFactorCodeButton, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: twoFactorCodeTextfield as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: twoFactorCodeTextfield as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            twoFactorCodeTextfieldHeightConstraint,
        ])
        twoFactorInfoLabelHeightConstraint = NSLayoutConstraint(item: twoFactorInfoLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 0)
        view.addConstraints([
            NSLayoutConstraint(item: twoFactorInfoLabel as Any, attribute: .top, relatedBy: .equal, toItem: twoFactorCodeTextfield, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: twoFactorInfoLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: twoFactorInfoLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            twoFactorInfoLabelHeightConstraint,
        ])
        view.addConstraints([
            NSLayoutConstraint(item: infoLabel as Any, attribute: .top, relatedBy: .equal, toItem: twoFactorInfoLabel, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: passwordInfoIconImageView as Any, attribute: .bottom, relatedBy: .equal, toItem: passwordTextfield, attribute: .top, multiplier: 1.0, constant: -8),
            NSLayoutConstraint(item: passwordInfoIconImageView as Any, attribute: .right, relatedBy: .equal, toItem: passwordTextfield, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: passwordInfoIconImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: passwordInfoIconImageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        forgotPasswordButtonTopConstraint = NSLayoutConstraint(item: forgotPasswordButton as Any, attribute: .top, relatedBy: .equal, toItem: passwordTextfield, attribute: .bottom, multiplier: 1.0, constant: 24)
        view.addConstraints([
            forgotPasswordButtonTopConstraint,
            NSLayoutConstraint(item: forgotPasswordButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: forgotPasswordButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        signInButtonBottomConstraint = NSLayoutConstraint(item: continueButton as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -24)
        view.addConstraints([
            signInButtonBottomConstraint,
            NSLayoutConstraint(item: continueButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: continueButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: continueButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: continueButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: continueButton, attribute: .centerX, multiplier: 1.0, constant: 0),
        ])
    }

    func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc func keyboardWillShow(_: Notification) {
        view.removeConstraint(signInButtonBottomConstraint)
        signInButtonBottomConstraint = NSLayoutConstraint(item: continueButton as Any, attribute: .top, relatedBy: .equal, toItem: forgotPasswordButton, attribute: .bottom, multiplier: 1.0, constant: 24)
        view.addConstraints([
            signInButtonBottomConstraint,
        ])
    }

    @objc func keyboardWillHide(_: Notification) {
        view.removeConstraint(signInButtonBottomConstraint)
        signInButtonBottomConstraint = NSLayoutConstraint(item: continueButton as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -24)
        view.addConstraints([
            signInButtonBottomConstraint,
        ])
    }
}

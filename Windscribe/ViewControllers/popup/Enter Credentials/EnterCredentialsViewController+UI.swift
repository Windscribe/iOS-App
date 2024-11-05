//
//  EnterCredentialsViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension EnterCredentialsViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.layer.opacity = 0.97
        backgroundView.backgroundColor = UIColor.midnight
        view.addSubview(backgroundView)

        headlineLabel = UILabel()
        headlineLabel.adjustsFontSizeToFitWidth = true
        headlineLabel.textAlignment = .center
        headlineLabel.font = UIFont.bold(size: 28)
        headlineLabel.textColor = UIColor.white
        view.addSubview(headlineLabel)

        iconView = UIImageView(image: UIImage(named: ImagesAsset.enterCredentials))
        iconView.contentMode = .scaleAspectFit
        view.addSubview(iconView)

        descriptionLabel = UILabel()
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.text = TextsAsset.EnterCredentialsAlert.message
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.text(size: 14)
        descriptionLabel.textColor = UIColor.white
        view.addSubview(descriptionLabel)

        titleTextField = WSTextField()
        titleTextField.attributedPlaceholder =
            NSAttributedString(string: TextsAsset.configTitle,
                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        titleTextField.backgroundColor = UIColor.clear
        titleTextField.textColor = UIColor.white
        titleTextField.layer.opacity = 0.55
        titleTextField.font = UIFont.bold(size: 18)
        titleTextField.autocorrectionType = .no
        titleTextField.autocapitalizationType = .none
        view.addSubview(titleTextField)

        usernameTextField = WSTextField()
        usernameTextField.attributedPlaceholder =
            NSAttributedString(string: TextsAsset.username,
                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        usernameTextField.backgroundColor = UIColor.clear
        usernameTextField.textColor = UIColor.white
        usernameTextField.layer.opacity = 0.55
        usernameTextField.font = UIFont.bold(size: 18)
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        view.addSubview(usernameTextField)

        passwordTextField = WSTextField()
        passwordTextField.isSecureTextEntry = true
        passwordTextField.attributedPlaceholder =
            NSAttributedString(string: TextsAsset.password,
                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        passwordTextField.backgroundColor = UIColor.clear
        passwordTextField.textColor = UIColor.white
        passwordTextField.layer.opacity = 0.55
        passwordTextField.font = UIFont.bold(size: 18)
        passwordTextField.autocorrectionType = .no
        passwordTextField.autocapitalizationType = .none
        view.addSubview(passwordTextField)

        saveCredentialsLabel = UILabel()
        saveCredentialsLabel.text = TextsAsset.EnterCredentialsAlert.saveCredentials
        saveCredentialsLabel.numberOfLines = 1
        saveCredentialsLabel.textAlignment = .left
        saveCredentialsLabel.font = UIFont.text(size: 18)
        saveCredentialsLabel.textColor = UIColor.white
        view.addSubview(saveCredentialsLabel)

        saveCredentialsButtonBottomBorder = UIView()
        saveCredentialsButtonBottomBorder.backgroundColor = UIColor.white
        saveCredentialsButtonBottomBorder.layer.opacity = 0.05
        view.addSubview(saveCredentialsButtonBottomBorder)

        saveCredentialsButton = CheckMarkButton(isDarkMode: viewModel.isDarkMode)
        checkMarkButtonAreaButton = UIButton()
        checkMarkButtonAreaButton.addTarget(self, action: #selector(saveCredentialsButtonTapped), for: .touchUpInside)
        view.addSubview(checkMarkButtonAreaButton)
        view.addSubview(saveCredentialsButton)

        submitButton = WSActionButton(type: .system)
        submitButton.enable()
        submitButton.titleLabel?.font = UIFont.text(size: 18)
        submitButton.layer.opacity = 0.4
        submitButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(submitButton)

        cancelButton = UIButton()
        cancelButton.setImage(UIImage(named: ImagesAsset.closeIcon), for: .normal)
        view.addSubview(cancelButton)
    }

    @objc func saveCredentialsButtonTapped() {
        saveCredentialsButton.toggle()
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        saveCredentialsLabel.translatesAutoresizingMaskIntoConstraints = false
        saveCredentialsButton.translatesAutoresizingMaskIntoConstraints = false
        checkMarkButtonAreaButton.translatesAutoresizingMaskIntoConstraints = false
        saveCredentialsButtonBottomBorder.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let isIphone5orLess = UIDevice.current.isIphone5orLess()

        // MARK: - Contraints

        showTitleConstraint = usernameTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16)
        showTitleConstraint?.isActive = true
        hideTitleContraint = usernameTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16)
        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // cancelButton
            cancelButton.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: UIScreen.hasTopNotch ? 54 : 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.widthAnchor.constraint(equalToConstant: 32),
            cancelButton.heightAnchor.constraint(equalToConstant: 32),

            // cancelButton
            isIphone5orLess ? iconView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 24)
                : iconView.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 36),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 57),
            iconView.heightAnchor.constraint(equalToConstant: 85),

            // headlineLabel
            headlineLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            headlineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            headlineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            headlineLabel.heightAnchor.constraint(equalToConstant: 42),

            // descriptionLabel
            descriptionLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),

            // titleTextField
            titleTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),

            // usernameTextField
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),

            // passwordTextField
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 14),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),

            // saveCredentialsLabel
            saveCredentialsLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            saveCredentialsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            saveCredentialsLabel.heightAnchor.constraint(equalToConstant: 50),

            // checkMarkButtonAreaButton
            checkMarkButtonAreaButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            checkMarkButtonAreaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            checkMarkButtonAreaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            checkMarkButtonAreaButton.heightAnchor.constraint(equalToConstant: 50),

            // saveCredentialsButton
            saveCredentialsButton.centerYAnchor.constraint(equalTo: saveCredentialsLabel.centerYAnchor),
            saveCredentialsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveCredentialsButton.widthAnchor.constraint(equalToConstant: 16),
            saveCredentialsButton.heightAnchor.constraint(equalToConstant: 16),

            // saveCredentialsButtonBottomBorder
            saveCredentialsButtonBottomBorder.bottomAnchor.constraint(equalTo: saveCredentialsLabel.bottomAnchor),
            saveCredentialsButtonBottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            saveCredentialsButtonBottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            saveCredentialsButtonBottomBorder.heightAnchor.constraint(equalToConstant: 2),

            // submitButton
            submitButton.topAnchor.constraint(equalTo: saveCredentialsLabel.bottomAnchor, constant: 32),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
}

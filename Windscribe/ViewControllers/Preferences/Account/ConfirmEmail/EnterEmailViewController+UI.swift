//
//  EnterEmailViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-20.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

extension EnterEmailViewController {
    func addViews() {
        backButton = LargeTapAreaImageButton()
        backButton.setImage(UIImage(named: ImagesAsset.prefBackIcon), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        self.view.addSubview(backButton)

        titleLabel = UILabel()
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)

        emailLabel = UILabel()
        emailLabel.font = UIFont.bold(size: 16)
        emailLabel.textAlignment = .left
        self.view.addSubview(emailLabel)

        emailTextField = LoginTextField(isDarkMode: viewModel.isDarkMode)
        emailTextField.addTarget(self, action: #selector(emailTextFieldValueChanged), for: .editingChanged)
        if let session = viewModel.sessionManager.session, session.isUserPro {
            emailTextField.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        } else {
            emailTextField.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 100)
        }

        self.view.addSubview(emailTextField)

        emailInfoLabel = UILabel()
        emailInfoLabel.font = UIFont.text(size: 12)
        emailInfoLabel.textAlignment = .right
        emailInfoLabel.layer.opacity = 0.5
        self.view.addSubview(emailInfoLabel)

        if let session = viewModel.sessionManager.session, session.isUserPro {
            emailInfoLabel.isHidden = true
        }

        infoLabel = UILabel()
        infoLabel.font = UIFont.text(size: 12)
        infoLabel.textAlignment = .left
        infoLabel.layer.opacity = 0.5
        self.view.addSubview(infoLabel)

        continueButton = UIButton(type: .system)
        continueButton.layer.cornerRadius = 26
        continueButton.clipsToBounds = true
        self.view.addSubview(continueButton)
        self.disableContinueButton()

        loadingView = UIActivityIndicatorView(style: .gray)
        self.view.addSubview(loadingView)

    }

    func enableContinueButton() {
        continueButtonEnabled.onNext(true)
        continueButton.layer.opacity = 1.0
        continueButton.isEnabled = true
    }

    func disableContinueButton() {
        continueButtonEnabled.onNext(false)
        continueButton.layer.opacity = 0.1
        continueButton.isEnabled = false
    }

    @objc func emailTextFieldValueChanged() {
        guard let emaitText = emailTextField.text else { return }
        if emaitText.count > 3 && emaitText.contains("@") && emaitText.contains(".") {
            self.enableContinueButton()
        } else {
            self.disableContinueButton()
        }
    }

    func addAutoLayoutConstraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                NSLayoutConstraint(item: backButton as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 70)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: backButton as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 32)
                ])
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: backButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: backButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: backButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 32)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: titleLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.backButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: emailLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.backButton, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: emailLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: emailTextField as Any, attribute: .top, relatedBy: .equal, toItem: self.emailLabel, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: emailTextField as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: emailTextField as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: emailTextField as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: emailInfoLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.emailTextField, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: emailInfoLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.emailTextField, attribute: .centerY, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: infoLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.emailTextField, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: infoLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -16)
            ])
        continueButtonBottomConstraint = NSLayoutConstraint(item: continueButton as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -24)
        self.view.addConstraints([
            continueButtonBottomConstraint,
            NSLayoutConstraint(item: continueButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: continueButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: continueButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: self.continueButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.continueButton, attribute: .centerX, multiplier: 1.0, constant: 0)
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

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardHeight = getKeyBoardHeight(notification: notification) else { return }
        changeContinueButtomBottomMargin(constant: -(keyboardHeight + 24))
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        changeContinueButtomBottomMargin(constant: -24)
    }

    private func changeContinueButtomBottomMargin(constant: CGFloat) {
        self.view.removeConstraint(continueButtonBottomConstraint)
        continueButtonBottomConstraint.constant = constant
        self.view.addConstraints([continueButtonBottomConstraint])
    }

    private func getKeyBoardHeight(notification: Notification) -> CGFloat? {
        guard let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil }
        let keyboardRectangle = keyboardFrame.cgRectValue
        return keyboardRectangle.height
    }
}

//
//  EnterEmailViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-20.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class EnterEmailViewController: WSNavigationViewController {
    var router: EmailRouter!, viewModel: EnterEmailViewModel!, logger: FileLogger!

    // MARK: - UI elements
    var emailLabel: UILabel!
    var emailTextField: LoginTextField!
    var continueButton: UIButton!
    var loadingView: UIActivityIndicatorView!
    var emailInfoLabel, infoLabel: UILabel!

    var continueButtonBottomConstraint: NSLayoutConstraint!

    lazy var continueButtonEnabled = { BehaviorSubject(value: continueButton.isEnabled) }()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Add Email View")
        self.addViews()
        self.addAutoLayoutConstraints()
        self.titleLabel.text = TextsAsset.addEmail

        if let session = viewModel.sessionManager.session, session.isUserPro {
            self.emailInfoLabel.isHidden = true
        }

        self.addNotificationObservers()
        bindViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emailTextField.becomeFirstResponder()
    }

    override func setupLocalized() {
        continueButton.setTitle(TextsAsset.continue, for: .normal)
        infoLabel.text = TextsAsset.addEmailInfo
        emailInfoLabel.text = "\(TextsAsset.get10GbAMonth)"
        emailTextField.text = sessionManager.session?.email
        emailLabel.text = TextsAsset.yourEmail
        titleLabel.text = TextsAsset.addEmail
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupViews(isDark: isDark)
            self.view.backgroundColor = ThemeUtils.backgroundColor(isDarkMode: isDark)
            titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            emailLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            emailInfoLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            infoLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
        }).disposed(by: disposeBag)

        Observable.combineLatest(continueButtonEnabled.asObservable(), viewModel.isDarkMode.asObservable()).bind { (isEnabled, isDark) in
            let backgroundColor = isEnabled ? UIColor.seaGreen : ThemeUtils.wrapperColor(isDarkMode: isDark)
            self.continueButton.backgroundColor = backgroundColor
            let color = isEnabled ? UIColor.midnight : ThemeUtils.primaryTextColor50(isDarkMode: isDark)
            self.continueButton.setTitleColor(color, for: .normal)
        }.disposed(by: disposeBag)

        continueButton.rx.tap.bind { [self] in
            self.continueButtonTapped()
        }.disposed(by: disposeBag)
    }

    private func continueButtonTapped() {
        guard let emailText = emailTextField.text else { return }
        logger.logI(self, "User tapped to submit email.")
        self.showLoading()
        self.continueButton.isEnabled = false
        viewModel.changeEmailAddress(email: emailText).observe(on: MainScheduler.instance).subscribe(onSuccess: { [self] _ in
            DispatchQueue.main.async { [ self] in
                self.endLoading()
                self.continueButton.isEnabled = true
                self.router.routeTo(to: RouteID.confirmEmail(delegate: self), from: self)

            }
        }, onFailure: { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                self?.endLoading()
                self?.continueButton.isEnabled = true
                if error.localizedDescription == Errors.emailExists.localizedDescription {
                    self?.viewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.emailIsTaken,
                        buttonText: "Ok"
                    )
                } else if error.localizedDescription == Errors.disposableEmail.localizedDescription {
                    self?.viewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.disposableEmail,
                        buttonText: "Ok"
                    )
                } else if error.localizedDescription == Errors.cannotChangeExistingEmail.localizedDescription {
                    self?.viewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.cannotChangeExistingEmail,
                        buttonText: "Ok"
                    )
                    self?.navigationController?.popToRootViewController(animated: true)
                } else if error.localizedDescription == Errors.noNetwork.localizedDescription{
                    self?.viewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.noNetworksAvailable,
                        buttonText: "Ok"
                    )
                } else {
                    self?.viewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.pleaseContactSupport,
                        buttonText: "Ok"
                    )
                }
            }
        }).disposed(by: disposeBag)
    }

}

extension EnterEmailViewController: ConfirmEmailViewControllerDelegate {

    func dismissWith(action: ConfirmEmailAction) {
        router?.dismissPopup(action: action, navigationVC: self.navigationController)
    }

}

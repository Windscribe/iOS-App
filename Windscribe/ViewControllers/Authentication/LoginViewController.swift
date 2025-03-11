//
//  LoginViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-09.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import IQKeyboardManagerSwift
import RxCocoa
import RxSwift
import UIKit

class LoginViewController: WSNavigationViewController {
    // MARK: - UI properties

    var scrollView: UIScrollView!
    var usernameLabel, passwordLabel: UILabel!
    var usernameTextfield: LoginTextField!
    var passwordTextfield: PasswordTextField!
    var twoFactorCodeTextfield: LoginTextField!
    var usernameInfoIconImageView, passwordInfoIconImageView: UIImageView!
    var twoFactorCodeButton, continueButton, forgotPasswordButton: UIButton!
    var loadingView: UIActivityIndicatorView!
    var twoFactorInfoLabel, infoLabel: UILabel!
    var twoFactorCodeTextfieldHeightConstraint, twoFactorInfoLabelHeightConstraint, signInButtonBottomConstraint, forgotPasswordButtonTopConstraint: NSLayoutConstraint!

    // MARK: - State properties

    var viewModel: LoginViewModel!, router: LoginRouter!, logger: FileLogger!

    // MARK: - UI Events

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Login View")
        setupView()
        bindViews()
    }

    override func setupLocalized() {
        titleLabel.text = TextsAsset.login
        continueButton.setTitle(TextsAsset.continue, for: .normal)
        forgotPasswordButton.setTitle(TextsAsset.forgotPassword, for: .normal)
        twoFactorCodeButton.setTitle(TextsAsset.twoFactorCode, for: .normal)
        twoFactorInfoLabel.text = "If enabled, use an authentication app to generate the code.".localize()
        passwordLabel.text = TextsAsset.password
        usernameLabel.text = TextsAsset.username
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 150
    }

    @objc func tappedOnScreen() {
        usernameTextfield.resignFirstResponder()
        passwordTextfield.resignFirstResponder()
    }

    // MARK: - Setup and Bind views

    private func setupView() {
        addViews()
        addAutoLayoutConstraints()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedOnScreen))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapRecognizer)
    }

    private func bindViews() {
        viewModel.showLoadingView.bind { [weak self] show in
            self?.loadingView.startAnimating()
            self?.usernameTextfield.isEnabled = !show
            self?.passwordTextfield.isEnabled = !show
            self?.loadingView.isHidden = !show
            if show {
                self?.continueButton.setTitle(nil, for: .normal)
            } else {
                self?.continueButton.setTitle(TextsAsset.continue, for: .normal)
            }
        }.disposed(by: disposeBag)
        viewModel.show2faCodeField.bind { [self] show in
            if show {
                setTwoFactorCodeVisibility(forceShow: show)
            }
        }.disposed(by: disposeBag)
        viewModel.isDarkMode.subscribe { [self] isDarkMode in
            self.usernameLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self.passwordLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self.twoFactorInfoLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self.twoFactorCodeButton.setTitleColor(ThemeUtils.primaryTextColor(isDarkMode: isDarkMode), for: .normal)
            self.forgotPasswordButton.setTitleColor(ThemeUtils.primaryTextColor(isDarkMode: isDarkMode), for: .normal)
            self.continueButton.setTitleColor(ThemeUtils.primaryTextColorInvert(isDarkMode: isDarkMode), for: .normal)
            self.setupViews(isDark: isDarkMode)
        }.disposed(by: disposeBag)
        Observable.combineLatest(viewModel.failedState.distinctUntilChanged(), viewModel.isDarkMode.asObservable()).bind { [weak self] state, isDarkMode in
            switch state {
            case let .username(error):
                self?.usernameTextfield.textColor = UIColor.failRed
                self?.usernameInfoIconImageView.isHidden = false
                self?.infoLabel.isHidden = false
                self?.infoLabel.text = error
            case let .network(error):
                self?.usernameTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                self?.passwordTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                self?.usernameInfoIconImageView.isHidden = true
                self?.passwordInfoIconImageView.isHidden = true
                self?.infoLabel.isHidden = false
                self?.infoLabel.text = error
            case let .api(error):
                self?.usernameTextfield.textColor = UIColor.failRed
                self?.usernameInfoIconImageView.isHidden = false
                self?.passwordTextfield.textColor = UIColor.failRed
                self?.passwordInfoIconImageView.isHidden = false
                self?.infoLabel.isHidden = false
                self?.infoLabel.text = error
            case let .twoFa(error):
                self?.infoLabel.isHidden = false
                self?.infoLabel.text = error
            case .none:
                self?.usernameTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                self?.passwordTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                self?.usernameInfoIconImageView.isHidden = true
                self?.passwordInfoIconImageView.isHidden = true
                self?.infoLabel.isHidden = true
                self?.infoLabel.text = ""
            default:
                self?.logger.logD(self ?? "Unknown", "default case")
            }
        }.disposed(by: disposeBag)
        continueButton.rx.tap.bind { [weak self] in
            guard let username = self?.usernameTextfield.text,
                  let password = self?.passwordTextfield.text else { return }
            self?.viewModel.continueButtonTapped(username: username, password: password, twoFactorCode: self?.twoFactorCodeTextfield.text)
        }.disposed(by: disposeBag)
        forgotPasswordButton.rx.tap.bind { [weak self] in
            self?.openLink(url: Links.forgotPassword)
        }.disposed(by: disposeBag)
        twoFactorCodeButton.rx.tap.bind { [self] in
            setTwoFactorCodeVisibility(forceShow: false)
        }.disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .bind { [weak self] _ in
                self?.viewModel.keyBoardWillShow()
            }.disposed(by: disposeBag)
        viewModel.routeToMainView.bind { [self] _ in
            self.logger.logD(self, "Moving to home screen.")
            DispatchQueue.main.async {
                self.router.routeTo(to: RouteID.home, from: self)
            }
        }.disposed(by: disposeBag)

        Observable.combineLatest(usernameTextfield.rx.text.asObservable(),
                                 viewModel.isDarkMode.asObservable()).bind { _, isDarkMode in
            self.loginTextFieldValueChanged(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
        Observable.combineLatest(passwordTextfield.rx.text.asObservable(),
                                 viewModel.isDarkMode.asObservable()).bind { _, isDarkMode in
            self.loginTextFieldValueChanged(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }

    // MARK: - Helper

    private func setTwoFactorCodeVisibility(forceShow: Bool = false) {
        view.removeConstraint(forgotPasswordButtonTopConstraint)
        var viewToAttach = passwordTextfield as Any
        if twoFactorCodeTextfieldHeightConstraint.constant == 48 && forceShow == false {
            twoFactorCodeTextfieldHeightConstraint.constant = 0
            twoFactorInfoLabelHeightConstraint.constant = 0
        } else {
            twoFactorCodeTextfieldHeightConstraint.constant = 48
            twoFactorInfoLabelHeightConstraint.constant = 14
            viewToAttach = infoLabel as Any
        }
        forgotPasswordButtonTopConstraint = NSLayoutConstraint(
            item: forgotPasswordButton as Any,
            attribute: .top,
            relatedBy: .equal,
            toItem: viewToAttach,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 24
        )
        view.addConstraint(forgotPasswordButtonTopConstraint)
    }

    private func loginTextFieldValueChanged(isDarkMode: Bool) {
        guard let usernameTextCount = usernameTextfield.text?.count, let passwordTextCount = passwordTextfield.text?.count else { return }
        if usernameTextCount > 2 && passwordTextCount > 2 {
            continueButton.backgroundColor = UIColor.seaGreen
            continueButton.setTitleColor(UIColor.midnight, for: .normal)
            continueButton.isEnabled = true
        } else {
            continueButton.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode)
            continueButton.setTitleColor(ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode), for: .normal)
            continueButton.isEnabled = false
        }
    }
}

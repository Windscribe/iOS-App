//
//  LoginViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 22/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class LoginViewController: PreferredFocusedViewController {
    @IBOutlet var loginButton: WSRoundButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var passwordTextField: PasswordTextFieldTv!
    @IBOutlet var forgotButton: UIButton!
    @IBOutlet var loginTitle: UILabel!
    @IBOutlet var usernameTextField: WSTextFieldTv!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var description1: UILabel!
    @IBOutlet var orLabel: UILabel!
    @IBOutlet var description2: UILabel!
    @IBOutlet var generateCodeButton: WSRoundButton!
    @IBOutlet var codeDisplayLabel: UILabel!
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var description2FA: UILabel!
    @IBOutlet var textField2FA: WSTextFieldTv!
    var loadingView: UIActivityIndicatorView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var infoView: UIView!
    var is2FA: Bool = false

    // MARK: - State properties

    var viewModel: LoginViewModelOld!, logger: FileLogger!, router: LoginRouter!
    let disposeBag = DisposeBag()

    private var credentials: (String?, String?) = (nil, nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        if is2FA {
            logger.logD(self, "Displaying Login Screen with 2fa.")
            setup2FA()
        } else {
            logger.logD(self, "Displaying Login Screen.")
            setup()
        }
        setupCommonUI()
        bindView()
        setupLocalized()
        setupSwipeDownGesture()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for press in presses {
            if loginButton != nil && loginButton.isFocused {
                if press.type == .leftArrow {
                    myPreferredFocusedView = generateCodeButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                }
            }
            if passwordTextField != nil && passwordTextField.isFocused {
                if press.type == .rightArrow {
                    myPreferredFocusedView = passwordTextField.showHidePasswordButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                }
            }
        }
    }

    private func setupSwipeDownGesture() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if loginButton != nil && loginButton.isFocused {
                myPreferredFocusedView = generateCodeButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if passwordTextField != nil && passwordTextField.isFocused {
                myPreferredFocusedView = passwordTextField.showHidePasswordButton
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    func setup() {
        loadingView = UIActivityIndicatorView(style: .large)
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        ])
        passwordTextField.isSecureTextEntry = true
        loginTitle.font = UIFont.bold(size: 35)
        forgotButton.titleLabel?.font = UIFont.text(size: 35)
        forgotButton.titleLabel?.minimumScaleFactor = 0.5
        forgotButton.titleLabel?.numberOfLines = 1
        forgotButton.titleLabel?.adjustsFontSizeToFitWidth = true
        forgotButton.setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        forgotButton.setTitleColor(.white, for: .focused)
        codeDisplayLabel.backgroundColor = .whiteWithOpacity(opacity: 0.15)
        codeDisplayLabel.font = UIFont.text(size: 35)
        codeDisplayLabel.layer.cornerRadius = 5
        codeDisplayLabel.clipsToBounds = true

        titleLabel.font = UIFont.bold(size: 35)
        description1.font = UIFont.text(size: 35)
        description2.font = UIFont.text(size: 35)

        myPreferredFocusedView = usernameTextField
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    func setupLocalized() {
        titleLabel.text = TextsAsset.TVAsset.lazyLogin
        description1.text = TextsAsset.TVAsset.lazyLoginDescription
        orLabel.text = TextsAsset.TVAsset.or
        description2.text = TextsAsset.TVAsset.lazyLoginDescription2
        generateCodeButton.setTitle(TextsAsset.TVAsset.generateCode, for: .normal)
        loginTitle.text = TextsAsset.TVAsset.manualLogin
        usernameTextField.placeholder = TextsAsset.Authentication.username
        passwordTextField.placeholder = TextsAsset.Authentication.password
        loginButton.setTitle(TextsAsset.login.uppercased(), for: .normal)

        backButton.setTitle(TextsAsset.back, for: .normal)
        forgotButton.setTitle(TextsAsset.Authentication.forgotPassword, for: .normal)
    }

    func setupCommonUI() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            view.backgroundColor = .blue
        }
        backButton.titleLabel?.font = UIFont.text(size: 35)
        backButton.setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        backButton.setTitleColor(.white, for: .focused)
    }

    func setup2FA() {
        credentials = (usernameTextField?.text, passwordTextField?.text)
        let name = "Login2FA"
        let bundle = Bundle(for: type(of: self))
        guard let view = bundle.loadNibNamed(name, owner: self, options: nil)?.first as? UIView else {
            fatalError("Nib not found.")
        }
        self.view = view
        welcomeLabel.font = UIFont.bold(size: 60)
        description2FA.font = UIFont.text(size: 35)
        description2FA.textColor = .whiteWithOpacity(opacity: 0.50)
        description2FA.text = TextsAsset.TVAsset.twofaDescription
        description2FA.text = TextsAsset.TVAsset.twofaDescription
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == loginButton {
            loginButton.layer.borderColor = UIColor.clear.cgColor
        } else {
            loginButton.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        }

        if context.nextFocusedView == generateCodeButton {
            generateCodeButton?.layer.borderColor = UIColor.clear.cgColor
        } else if generateCodeButton != nil {
            generateCodeButton?.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        }
        DispatchQueue.main.async {
            if context.nextFocusedView == self.usernameTextField {
                self.usernameTextField.attributedPlaceholder = NSAttributedString(
                    string: TextsAsset.Authentication.username,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.grayWithOpacity(opacity: 0.60)])
            } else {
                self.usernameTextField.attributedPlaceholder = NSAttributedString(
                    string: TextsAsset.Authentication.username,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.whiteWithOpacity(opacity: 0.50)])
            }
            if context.nextFocusedView == self.passwordTextField {
                self.passwordTextField.attributedPlaceholder = NSAttributedString(
                    string: TextsAsset.Authentication.password,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.grayWithOpacity(opacity: 0.60)])
            } else {
                self.passwordTextField.attributedPlaceholder = NSAttributedString(
                    string: TextsAsset.Authentication.password,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.whiteWithOpacity(opacity: 0.50)])
            }
        }

    }

    @IBAction func backButtonAction(_: Any?) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func loginButtonAction(_: Any?) {
        guard let username = usernameTextField?.text ?? credentials.0,
              let password = passwordTextField?.text ?? credentials.1 else { return }
        viewModel.continueButtonTapped(username: username, password: password, twoFactorCode: textField2FA?.text)
    }

    func bindView() {
        viewModel.showLoadingView.bind { [weak self] show in
            self?.loadingView.startAnimating()
            self?.usernameTextField.isEnabled = !show
            self?.passwordTextField?.isEnabled = !show
            self?.loadingView.isHidden = !show
        }.disposed(by: disposeBag)
        loginButton.rx.primaryAction.bind { [weak self] in
            self?.loginButtonAction(nil)
        }.disposed(by: disposeBag)
        forgotButton.rx.primaryAction.bind { [self] in
            router.routeTo(to: .forgotPassword, from: self)
            self.logger.logD(self, "Moving to forgot password screen.")
        }.disposed(by: disposeBag)
        backButton.rx.primaryAction.bind { [weak self] in
            self?.backButtonAction(nil)
        }.disposed(by: disposeBag)
        viewModel.routeToMainView.bind { [self] _ in
            self.logger.logD(self, "Moving to home screen.")
            router.routeTo(to: RouteID.home, from: self)
        }.disposed(by: disposeBag)
        generateCodeButton.rx.primaryAction.bind { [weak self] in
            self?.viewModel.generateCodeTapped()
        }.disposed(by: disposeBag)
        viewModel.xpressCode.bind { code in
            DispatchQueue.main.async { [weak self] in
                if let code = code, code.count > 0 {
                    self?.codeDisplayLabel.isHidden = false
                    self?.generateCodeButton.isHidden = true
                    self?.codeDisplayLabel.text = code
                } else {
                    self?.codeDisplayLabel.isHidden = true
                    self?.generateCodeButton.isHidden = false
                    self?.codeDisplayLabel.text = code
                }
            }
        }.disposed(by: disposeBag)
        viewModel.failedState.distinctUntilChanged().bind { [weak self] state in
            switch state {
            case let .username(error), let .network(error), let .api(error), let .twoFa(error), let .loginCode(error):
                self?.infoView?.isHidden = false
                self?.infoLabel?.text = error
            case .none:
                self?.infoView?.isHidden = true
                self?.infoLabel?.text = ""
            }
        }.disposed(by: disposeBag)
        viewModel.show2faCodeField.bind { [self] show in
            if show {
                is2FA = show
                setup2FA()
                setupCommonUI()
            }
        }.disposed(by: disposeBag)
    }
}

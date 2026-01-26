//
//  LoginViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 22/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
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
    private var captchaOverlayView: UIView?
    private var captchaPopupView: CaptchaView?
    var is2FA: Bool = false

    // MARK: - State properties

    var viewModel: LoginViewModel!, logger: FileLogger!, router: LoginRouter!
    private var cancellables = Set<AnyCancellable>()

    private var credentials: (String?, String?) = (nil, nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        if is2FA {
            setup2FA()
        } else {
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
        viewModel.showLoadingView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                guard let self = self else { return }
                self.loadingView.startAnimating()
                self.usernameTextField.isEnabled = !show
                self.passwordTextField?.isEnabled = !show
                self.loadingView.isHidden = !show
            }
            .store(in: &cancellables)
        loginButton.wasSelected
            .sink { [weak self] _ in
                self?.loginButtonAction(nil)
            }
            .store(in: &cancellables)
        forgotButton.wasSelected
            .sink { [self] _ in
                router.routeTo(to: .forgotPassword, from: self)
                self.logger.logD("LoginViewController", "Moving to forgot password screen.")
            }
            .store(in: &cancellables)
        backButton.wasSelected
            .sink { [weak self] _ in
                self?.backButtonAction(nil)
            }
            .store(in: &cancellables)
        viewModel.routeToMainView
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                self.logger.logD("LoginViewController", "Moving to home screen.")
                router.routeTo(to: RouteID.home, from: self)
            }
            .store(in: &cancellables)
        generateCodeButton.wasSelected
            .sink { [weak self] _ in
                self?.viewModel.generateCodeTapped()
            }
            .store(in: &cancellables)
        viewModel.xpressCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] code in
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
            .store(in: &cancellables)
        viewModel.failedState
            .removeDuplicates()
            .sink { [weak self] state in
                switch state {
                case let .username(error), let .network(error), let .api(error), let .twoFa(error), let .loginCode(error):
                    self?.infoView?.isHidden = false
                    self?.infoLabel?.text = error
                case .none:
                    self?.infoView?.isHidden = true
                    self?.infoLabel?.text = ""
                }
            }
            .store(in: &cancellables)
        viewModel.show2faCodeField
            .sink { [self] show in
                if show {
                    is2FA = show
                    setup2FA()
                    setupCommonUI()
                }
            }
            .store(in: &cancellables)

        viewModel.showCaptchaViewModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] captchaVM in
                guard let self = self else { return }

                let captchaPopupView = CaptchaView()
                captchaPopupView.bind(to: captchaVM)

                captchaPopupView.submitTap
                  .receive(on: DispatchQueue.main)
                  .sink { code in
                    captchaVM.submitCaptcha.send(code)
                  }
                  .store(in: &self.cancellables)

                captchaPopupView.cancelTap
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        self?.dismissCaptchaPopup()
                    }
                    .store(in: &self.cancellables)

                captchaPopupView.refreshTap
                    .receive(on: DispatchQueue.main)
                    .sink {
                        captchaVM.refreshCaptcha.send(())
                    }
                    .store(in: &self.cancellables)

                captchaVM.captchaDismiss
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        self?.dismissCaptchaPopup()
                    }
                    .store(in: &self.cancellables)

                self.showCaptchaPopup(captchaPopupView: captchaPopupView)
            }
            .store(in: &cancellables)
    }

    private func showCaptchaPopup(captchaPopupView: CaptchaView) {
        // Create overlay view (dimmed background)
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.captchaOverlayView = overlayView

        // Add popup view on top of overlay
        captchaPopupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captchaPopupView)

        NSLayoutConstraint.activate([
            captchaPopupView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captchaPopupView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captchaPopupView.topAnchor.constraint(equalTo: view.topAnchor),
            captchaPopupView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.captchaPopupView = captchaPopupView

        // Animate fade in
        overlayView.alpha = 0
        captchaPopupView.alpha = 0

        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
            captchaPopupView.alpha = 1
        }

        DispatchQueue.main.async {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    private func dismissCaptchaPopup() {
        guard let overlayView = captchaOverlayView,
              let popupView = captchaPopupView else { return }

        UIView.animate(withDuration: 0.3, animations: {
            overlayView.alpha = 0
            popupView.alpha = 0
        }, completion: { _ in
            overlayView.removeFromSuperview()
            popupView.removeFromSuperview()
            self.captchaOverlayView = nil
            self.captchaPopupView = nil
        })
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let captchaPopup = captchaPopupView {
            return [captchaPopup]
        }
        return super.preferredFocusEnvironments
    }
}

//
//  LoginViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 22/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: WSRoundButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var passwordTextField: WSTextFieldTv!
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var loginTitle: UILabel!
    @IBOutlet weak var usernameTextField: WSTextFieldTv!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var description1: UILabel!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var description2: UILabel!
    @IBOutlet weak var generateCodeButton: WSRoundButton!
    @IBOutlet weak var codeDisplayLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var description2FA: UILabel!
    @IBOutlet weak var textField2FA: WSTextFieldTv!
    var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel!

    var myPreferredFocusedView: UIView?
    var is2FA: Bool = false

    // MARK: - State properties
    var viewModel: LoginViewModel!, logger: FileLogger!, router: LoginRouter!
    let disposeBag = DisposeBag()

    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }
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
    }

    func setup() {
        loadingView = UIActivityIndicatorView(style: .large)
        self.view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0)
        ])
        passwordTextField.isSecureTextEntry = true
        loginTitle.font = UIFont.bold(size: 35)
        forgotButton.titleLabel?.font = UIFont.text(size: 35)
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
        titleLabel.text = TvAssets.lazyLogin
        description1.text = TvAssets.lazyLoginDescription
        orLabel.text = TvAssets.or
        description2.text = TvAssets.lazyLoginDescription2
        generateCodeButton.titleLabel?.text = TvAssets.generateCode
        loginTitle.text = TvAssets.manualLogin
        usernameTextField.placeholder = TextsAsset.username
        passwordTextField.placeholder = TextsAsset.password
        loginButton.titleLabel?.text = TextsAsset.login
        backButton.titleLabel?.text = TextsAsset.back
        forgotButton.titleLabel?.text = TextsAsset.forgotPassword
        description2FA.text = TvAssets.twofaDescription
    }

    func setupCommonUI() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            self.view.backgroundColor = .blue
        }
        backButton.titleLabel?.font = UIFont.text(size: 35)
        backButton.setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        backButton.setTitleColor(.white, for: .focused)

    }

    func setup2FA() {
        let name = "Login2FA"
        let bundle = Bundle(for: type(of: self))
        guard let view = bundle.loadNibNamed(name, owner: self, options: nil)?.first as? UIView else {
            fatalError("Nib not found.")
        }
        self.view = view
        welcomeLabel.font = UIFont.bold(size: 60)
        description2FA.font = UIFont.text(size: 35)
        description2FA.textColor = .whiteWithOpacity(opacity: 0.50)
     //   bindView()

    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == loginButton {
            loginButton.layer.borderColor = UIColor.clear.cgColor
        } else {
            loginButton.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        }

        if context.nextFocusedView == generateCodeButton {
            generateCodeButton.layer.borderColor = UIColor.clear.cgColor
        } else if generateCodeButton != nil {
            generateCodeButton.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        }
    }

    func bindView() {
        viewModel.showLoadingView.bind { [weak self] show in
            self?.loadingView.startAnimating()
            self?.usernameTextField.isEnabled = !show
            self?.passwordTextField.isEnabled = !show
            self?.loadingView.isHidden = !show
        }.disposed(by: disposeBag)
        loginButton.rx.primaryAction.bind { [weak self] in
            guard let username = self?.usernameTextField?.text,
                  let password = self?.passwordTextField?.text else { return }
            self?.viewModel.continueButtonTapped(username: username, password: password, twoFactorCode: self?.textField2FA?.text)
        }.disposed(by: disposeBag)
        forgotButton.rx.primaryAction.bind { [ self] in
            router.routeTo(to: .forgotPassword, from: self)
            self.logger.logD(self, "Moving to forgot password screen.")
        }.disposed(by: disposeBag)
        backButton.rx.primaryAction.bind { [weak self] in
            self?.navigationController?.popViewController(animated: true)
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
        viewModel.failedState.distinctUntilChanged().bind { [weak self] (state) in
            switch state {
            case .username(let error), .network(let error), .api(let error), .twoFa(let error), .loginCode(let error):
                self?.infoLabel.isHidden = false
                self?.infoLabel.text = error
            case .none:
                self?.infoLabel.isHidden = true
                self?.infoLabel.text = ""

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

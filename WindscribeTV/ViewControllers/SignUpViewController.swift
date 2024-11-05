//
//  SignUpViewController.swift
//  Windscribe
//
//  Created by Bushra Sagir on 17/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class SignUpViewController: PreferredFocusedViewController {
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var signUpButton: WSRoundButton!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var infoView: UIView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var passwordTextField: PasswordTextFieldTv!
    @IBOutlet var forgotButton: UIButton!
    @IBOutlet var signUpTitle: UILabel!
    @IBOutlet var usernameTextField: WSTextFieldTv!
    var loadingView: UIActivityIndicatorView!

    // MARK: - State properties

    var viewModel: SignUpViewModel!, router: SignupRouter!, logger: FileLogger!
    var claimGhostAccount = false
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Signup Screen.")
        setup()
        setupLocalized()
        // Do any additional setup after loading the view.
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for press in presses {
            if passwordTextField.isFocused {
                if press.type == .rightArrow {
                    myPreferredFocusedView = passwordTextField.showHidePasswordButton
                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                }
            }
        }
    }

    func setup() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            view.backgroundColor = .blue
        }
        welcomeLabel.font = UIFont.bold(size: 60)
        passwordTextField.isSecureTextEntry = true
        signUpTitle.font = UIFont.bold(size: 35)

        forgotButton.titleLabel?.font = UIFont.text(size: 35)
        backButton.titleLabel?.font = UIFont.text(size: 35)
        forgotButton.setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        forgotButton.setTitleColor(.white, for: .focused)

        backButton.setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        backButton.setTitleColor(.white, for: .focused)
        loadingView = UIActivityIndicatorView(style: .large)
        loadingView.isHidden = true
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
        ])
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        bindView()
    }

    func setupLocalized() {
        welcomeLabel.text = TextsAsset.slogan
        signUpTitle.text = TextsAsset.signUp
        usernameTextField.placeholder = TextsAsset.username
        passwordTextField.placeholder = TextsAsset.password

        signUpButton.setTitle(TextsAsset.signUp.uppercased(), for: .normal)
        backButton.setTitle(TextsAsset.back, for: .normal)
        forgotButton.setTitle(TextsAsset.forgotPassword, for: .normal)
    }

    func bindView() {
        viewModel.showLoadingView.bind { [self] show in
            if show {
                showLoading()
            } else {
                hideLoading()
            }
        }.disposed(by: disposeBag)
        signUpButton.rx.primaryAction.bind { [self] in
            viewModel.continueButtonTapped(userName: usernameTextField.text, password: passwordTextField.text, email: "", referrelUsername: "", ignoreEmailCheck: true, claimAccount: claimGhostAccount, voucherCode: "")
        }.disposed(by: disposeBag)
        viewModel.failedState.bind { [weak self] state in
            self?.setFailureState(state: state)
        }.disposed(by: disposeBag)
        viewModel.routeTo.bind { [self] _ in
            self.logger.logD(self, "Moving to home screen.")
            router.routeTo(to: RouteID.home, from: self)
        }.disposed(by: disposeBag)
        forgotButton.rx.primaryAction.bind { [self] in
            router.routeTo(to: RouteID.forgotPassword, from: self)
        }.disposed(by: disposeBag)
    }

    private func setFailureState(state: SignUpErrorState) {
        switch state {
        case let .username(error):
            usernameTextField.textColor = UIColor.failRed
            infoLabel.text = error
            infoView.isHidden = false
        case let .password(error):
            passwordTextField.textColor = UIColor.failRed
            infoLabel.text = error
            infoView.isHidden = false
        case let .email(error):
            infoLabel.text = error
            infoLabel.textColor = UIColor.failRed
            infoView.isHidden = false
        case let .api(error):
            infoLabel.text = error
            infoLabel.textColor = UIColor.failRed
            infoView.isHidden = false
        case let .network(error):
            infoLabel.text = error
            infoLabel.textColor = UIColor.failRed
            infoView.isHidden = false
        case .none:
            infoView.isHidden = true
            infoLabel.text = ""
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == usernameTextField {
            usernameTextField.layer.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.15).cgColor
            passwordTextField.layer.backgroundColor = UIColor.clear.cgColor

        } else if context.nextFocusedView == passwordTextField {
            passwordTextField.layer.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.15).cgColor
            usernameTextField.layer.backgroundColor = UIColor.clear.cgColor
        }
    }

    func hideLoading() {
        loadingView.isHidden = true
    }

    func showLoading() {
        loadingView.startAnimating()
        loadingView.isHidden = false
    }

    @IBAction func backButtonAction(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_: UITextField) {
        viewModel.keyBoardWillShow()
    }
}

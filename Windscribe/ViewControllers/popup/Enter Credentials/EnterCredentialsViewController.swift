//
//  EnterCredentialsViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import IQKeyboardManagerSwift
import RxSwift
import UIKit

class EnterCredentialsViewController: WSUIViewController {
    var backgroundView: UIView!
    var headlineLabel: UILabel!
    var iconView: UIImageView!
    var descriptionLabel: UILabel!
    var titleTextField, usernameTextField, passwordTextField: WSTextField!
    var saveCredentialsLabel: UILabel!
    var checkMarkButtonAreaButton: UIButton!
    var saveCredentialsButton: CheckMarkButton!
    var saveCredentialsButtonBottomBorder: UIView!
    var submitButton: WSActionButton!
    var cancelButton: UIButton!
    var loadingAlert: UIAlertController!

    var hideTitleContraint: NSLayoutConstraint?
    var showTitleConstraint: NSLayoutConstraint?

    var viewModel: EnterCredentialsViewModelType!
    var logger: FileLogger!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Enter Custom Config Credentials View")
        IQKeyboardManager.shared.enable = true
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    private func bindViews() {
        viewModel.isUpdating.subscribe(onNext: { isUpdating in
            self.headlineLabel.text = isUpdating ? TextsAsset.EditCredentialsAlert.title : TextsAsset.EnterCredentialsAlert.title
            self.titleTextField.isHidden = !isUpdating
            self.submitButton.setTitle(isUpdating ? TextsAsset.save : TextsAsset.connect, for: .normal)

            if isUpdating {
                self.hideTitleContraint?.isActive = false
                self.showTitleConstraint?.isActive = true
            } else {
                self.showTitleConstraint?.isActive = false
                self.hideTitleContraint?.isActive = true
            }
        }).disposed(by: disposeBag)

        viewModel.title.subscribe(onNext: { self.titleTextField.text = $0 }).disposed(by: disposeBag)
        viewModel.password.subscribe(onNext: { self.passwordTextField.text = $0.base64Decoded() }).disposed(by: disposeBag)
        viewModel.username.subscribe(onNext: {
            self.usernameTextField.text = $0.base64Decoded()
            self.saveCredentialsButton.setStatus(!$0.isEmpty)
        }).disposed(by: disposeBag)

        submitButton.rx.tap.bind {
            self.viewModel.submit(title: self.titleTextField.text,
                                  username: self.usernameTextField.text,
                                  password: self.passwordTextField.text)
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        cancelButton.rx.tap.bind {
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        Observable.combineLatest(
            usernameTextField.rx.controlEvent([.editingChanged]).withLatestFrom(usernameTextField.rx.text.orEmpty).asObservable(),
            passwordTextField.rx.controlEvent([.editingChanged]).withLatestFrom(passwordTextField.rx.text.orEmpty).asObservable()
        )
        .subscribe(onNext: { username, password in
            (!username.isEmpty && !password.isEmpty) ? self.submitButton.enable() : self.submitButton.disable()
        }).disposed(by: disposeBag)
    }
}

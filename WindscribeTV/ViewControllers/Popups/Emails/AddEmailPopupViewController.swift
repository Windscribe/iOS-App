//
//  AddEmailPopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 21/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class AddEmailPopupViewController: BasePopUpViewController {
    var router: HomeRouter!, aeViewModel: EnterEmailViewModel!, logger: FileLogger!
    @IBOutlet weak var fieldStackView: UIStackView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var addEmailButton = WSPillButton()
    var emailTextField = WSTextFieldTv()
    
    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViews()
    }
    
    override func setup() {
        super.setup()
        addEmailButton.setTitle(TextsAsset.Account.addEmail, for: .normal)
        addEmailButton.setup(withHeight: 96.0)
        mainStackView.addArrangedSubview(addEmailButton)
        mainStackView.addArrangedSubview(UIView())
        bodyLabel.font = UIFont.regular(size: 34)
        
        emailTextField.text = aeViewModel.currentEmail
        emailTextField.placeholder = TextsAsset.email
        emailTextField.keyboardType = .emailAddress
        fieldStackView.addArrangedSubview(emailTextField)
    }
    
    //MARK: Setting up
    private func bindViews() {
        addEmailButton.rx.primaryAction.bind { [self] in
            continueButtonTapped()
        }.disposed(by: disposeBag)
    }
    
    //MARK: Actions
    private func showLoading() {
        loadingView.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func endLoading() {
        loadingView.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func continueButtonTapped() {
        guard let emailText = emailTextField.text else { return }
        logger.logE(self, "User tapped to submit email.")
        self.showLoading()
        self.addEmailButton.isEnabled = false
        aeViewModel.changeEmailAddress(email: emailText).observe(on: MainScheduler.instance).subscribe(onSuccess: { [self] _ in
            DispatchQueue.main.async { [ self] in
                self.endLoading()
                self.addEmailButton.isEnabled = true
                self.router.routeTo(to: RouteID.confirmEmail, from: self)
            }
        }, onFailure: { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                self?.endLoading()
                self?.addEmailButton.isEnabled = true
                if error.localizedDescription == Errors.emailExists.localizedDescription {
                    self?.aeViewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.emailIsTaken,
                        buttonText: TextsAsset.ok
                    )
                } else if error.localizedDescription == Errors.disposableEmail.localizedDescription {
                    self?.aeViewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.disposableEmail,
                        buttonText: TextsAsset.ok
                    )
                } else if error.localizedDescription == Errors.cannotChangeExistingEmail.localizedDescription {
                    self?.aeViewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.cannotChangeExistingEmail,
                        buttonText: TextsAsset.ok
                    )
                    self?.navigationController?.popToRootViewController(animated: true)
                } else {
                    self?.aeViewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: TextsAsset.pleaseContactSupport,
                        buttonText: TextsAsset.ok
                    )
                }
            }
        }).disposed(by: disposeBag)
    }
}
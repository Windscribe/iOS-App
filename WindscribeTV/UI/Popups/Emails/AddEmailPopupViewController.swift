//
//  AddEmailPopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 21/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit

class AddEmailPopupViewController: BasePopUpViewController {
    var router: HomeRouter!, aeViewModel: EnterEmailViewModel!
    @IBOutlet var fieldStackView: UIStackView!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    var addEmailButton = WSPillButton()
    var emailTextField = WSTextFieldTv()
    private var cancellables = Set<AnyCancellable>()

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD("AddEmailPopupViewController", "Add Email Popup Shown.")
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

    // MARK: Setting up

    private func bindViews() {
        addEmailButton.wasSelected
            .sink { [self] _ in
                continueButtonTapped()
            }
            .store(in: &cancellables)
    }

    // MARK: Actions

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
        logger.logD("AddEmailPopupViewController", "User tapped to submit email.")
        showLoading()
        addEmailButton.isEnabled = false
        aeViewModel.changeEmailAddress(email: emailText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.endLoading()
                self.addEmailButton.isEnabled = true

                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    if error.localizedDescription == Errors.emailExists.localizedDescription {
                        self.aeViewModel.alertManager.showSimpleAlert(
                            viewController: self,
                            title: TextsAsset.error,
                            message: TextsAsset.emailIsTaken,
                            buttonText: TextsAsset.ok
                        )
                    } else if error.localizedDescription == Errors.disposableEmail.localizedDescription {
                        self.aeViewModel.alertManager.showSimpleAlert(
                            viewController: self,
                            title: TextsAsset.error,
                            message: TextsAsset.disposableEmail,
                            buttonText: TextsAsset.ok
                        )
                    } else if error.localizedDescription == Errors.cannotChangeExistingEmail.localizedDescription {
                        self.aeViewModel.alertManager.showSimpleAlert(
                            viewController: self,
                            title: TextsAsset.error,
                            message: TextsAsset.cannotChangeExistingEmail,
                            buttonText: TextsAsset.ok
                        )
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        self.aeViewModel.alertManager.showSimpleAlert(
                            viewController: self,
                            title: TextsAsset.error,
                            message: TextsAsset.pleaseContactSupport,
                            buttonText: TextsAsset.ok
                        )
                    }
                }
            } receiveValue: { [self] _ in
                self.endLoading()
                self.addEmailButton.isEnabled = true
                self.router.routeTo(to: .confirmEmail(delegate: nil), from: self)
            }
            .store(in: &cancellables)
    }
}

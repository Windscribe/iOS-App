//
//  ConfirmEmailPopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 20/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class ConfirmEmailPopupViewController: BasePopUpViewController {
    var ceViewModel: ConfirmEmailViewModel!, logger: FileLogger!, router: HomeRouter!

    var resendButton = WSPillButton()
    var changeButton = WSPillButton()
    var closeButton = WSPillButton()

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViews()
    }

    // MARK: Setting up
    override func setup() {
        super.setup()
        resendButton.setTitle(TextsAsset.Account.resend, for: .normal)
        changeButton.setTitle(TextsAsset.EmailView.changeEmail, for: .normal)
        closeButton.setTitle(TextsAsset.EmailView.close, for: .normal)

        [resendButton, changeButton, closeButton].forEach { roundbutton in
            roundbutton.setup(withHeight: 96.0)
            mainStackView.addArrangedSubview(roundbutton)
        }
        mainStackView.addArrangedSubview(UIView())
    }

    private func bindViews() {
        resendButton.rx.primaryAction.bind { [self] in
            self.resendButtonTapped()
        }.disposed(by: disposeBag)
        changeButton.rx.primaryAction.bind { [self] in
            self.router.routeTo(to: .addEmail, from: self)
        }.disposed(by: disposeBag)
        closeButton.rx.primaryAction.bind { [self] in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }

    private func resendButtonTapped() {
        logger.logE(self, "User tapped Resend Email button.")
        resendButton.isEnabled = false
        resendButton.layer.opacity = 0.35
        ceViewModel.apiManager.confirmEmail().subscribe(onSuccess: { _ in
            self.ceViewModel.alertManager.showSimpleAlert(viewController: self,
                                                title: TextsAsset.ConfirmationEmailSentAlert.title, message: TextsAsset.ConfirmationEmailSentAlert.message,
                                                buttonText: TextsAsset.okay)
        }, onFailure: { _ in}).disposed(by: disposeBag)
    }
}

//
//  ConfirmEmailViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2020-02-03.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class ConfirmEmailViewController: WSUIViewController {
    var viewModel: ConfirmEmailViewModel!, logger: FileLogger!

    var backgroundView: UIView!
    var iconView: UIImageView!
    var titleLabel, infoLabel: UILabel!
    var resendButton, changeButton, closeButton: UIButton!

    weak var dismissDelegate: ConfirmEmailViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addAutolayoutConstraints()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSession),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        bindData()
    }

    private func bindData() {
        viewModel.localDatabase.getSession().subscribe(onNext: { [self] session in
            guard let session = session else { return }
            DispatchQueue.main.async {
                if session.emailStatus == true {
                    self.dismissDelegate?.dismissWith(action: .dismiss)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }, onError: { _ in }).disposed(by: disposeBag)

        changeButton.rx.tap.bind {
            self.dismissDelegate?.dismissWith(action: .enterEmail)
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        closeButton.rx.tap.bind {
            self.updateSession()
            self.dismissDelegate?.dismissWith(action: .dismiss)
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        resendButton.rx.tap.bind {
            self.resendButtonTapped()
        }.disposed(by: disposeBag)
    }

    @objc func updateSession() {
        viewModel.getSession()
    }

    private func resendButtonTapped() {
        logger.logI(self, "User tapped Resend Email button.")
        resendButton.isEnabled = false
        resendButton.layer.opacity = 0.35
        viewModel.apiManager.confirmEmail().subscribe(onSuccess: { _ in
            self.viewModel.alertManager.showSimpleAlert(viewController: self,
                                                        title: TextsAsset.ConfirmationEmailSentAlert.title, message: TextsAsset.ConfirmationEmailSentAlert.message,
                                                        buttonText: TextsAsset.okay)

        }, onFailure: { _ in }).disposed(by: disposeBag)
    }
}

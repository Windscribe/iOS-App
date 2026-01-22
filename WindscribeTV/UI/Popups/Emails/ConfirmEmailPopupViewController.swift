//
//  ConfirmEmailPopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 20/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit

class ConfirmEmailPopupViewController: BasePopUpViewController {
    var ceViewModel: ConfirmEmailViewModel!, router: HomeRouter!

    var resendButton = WSPillButton()
    var changeButton = WSPillButton()
    var closeButton = WSPillButton()
    private var cancellables = Set<AnyCancellable>()

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD("ConfirmEmailPopupViewController", "Confirm Email Popup Shown.")
        bindViews()
    }

    // MARK: Setting up

    override func setup() {
        super.setup()
        resendButton.setTitle(TextsAsset.Account.resend, for: .normal)
        changeButton.setTitle(TextsAsset.EmailView.changeEmail, for: .normal)
        closeButton.setTitle(TextsAsset.EmailView.close, for: .normal)

        for roundbutton in [resendButton, changeButton, closeButton] {
            roundbutton.setup(withHeight: 96.0)
            mainStackView.addArrangedSubview(roundbutton)
        }
        mainStackView.addArrangedSubview(UIView())
    }

    private func bindViews() {
        resendButton.wasSelected
            .sink { [self] _ in
                logger.logD("ConfirmEmailPopupViewController", "User tapped Resend Email button.")
                self.resendButtonTapped()
            }
            .store(in: &cancellables)
        changeButton.wasSelected
            .sink { [self] _ in
                logger.logD("ConfirmEmailPopupViewController", "User tapped Change Email button.")
                self.router.routeTo(to: .addEmail, from: self)
            }
            .store(in: &cancellables)
        closeButton.wasSelected
            .sink { [self] _ in
                logger.logD("ConfirmEmailPopupViewController", "User tapped Close button.")
                self.dismiss(animated: true, completion: nil)
            }
            .store(in: &cancellables)
    }

    private func resendButtonTapped() {
        resendButton.isEnabled = false
        resendButton.layer.opacity = 0.35

        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.ceViewModel.apiManager.confirmEmail()
                await MainActor.run {
                    self.ceViewModel.alertManager.showSimpleAlert(viewController: self,
                                                                  title: TextsAsset.ConfirmationEmailSentAlert.title,
                                                                  message: TextsAsset.ConfirmationEmailSentAlert.message,
                                                                  buttonText: TextsAsset.okay)
                }
            } catch {
                // Handle error silently as per original implementation
            }
        }
    }
}

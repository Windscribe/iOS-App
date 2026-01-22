//
//  AccountPopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 03/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit

class AccountPopupViewController: BasePopUpViewController {
    var accountPopupViewModel: AccountPopupModelType!
    private var cancellables = Set<AnyCancellable>()

    var actionButton = WSPillButton()
    var cancelButton = WSPillButton()

    @IBOutlet var imageView: UIImageView!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        logger?.logD("AccountPopupViewController", "Displaying Account Popup View")
        bindViews()
    }

    // MARK: Setting up

    override func setup() {
        super.setup()
        titleLabel?.text = ""
        headerLabel.isHidden = false
        for item in [actionButton, cancelButton] {
            item.setup(withHeight: 96.0)
            mainStackView.addArrangedSubview(item)
        }
        mainStackView.addArrangedSubview(UIView())
    }

    private func bindViews() {
        accountPopupViewModel.imageName
            .sink { [self] value in
                imageView.image = UIImage(named: value)
            }
            .store(in: &cancellables)
        accountPopupViewModel.title
            .sink { [self] value in
                headerLabel?.text = value
            }
            .store(in: &cancellables)
        accountPopupViewModel.description
            .sink { [self] value in
                bodyLabel.text = value
            }
            .store(in: &cancellables)

        accountPopupViewModel.actionButtonTitle
            .sink { [self] value in
                actionButton.setTitle(value, for: .normal)
                cancelButton.isHidden = value.isEmpty
            }
            .store(in: &cancellables)
        accountPopupViewModel.cancelButtonTitle
            .sink { [self] value in
                cancelButton.setTitle(value, for: .normal)
                cancelButton.isHidden = value.isEmpty
            }
            .store(in: &cancellables)

        actionButton.wasSelected
            .sink { [self] _ in
                accountPopupViewModel.action(viewController: self)
            }
            .store(in: &cancellables)
        cancelButton.wasSelected
            .sink { [self] _ in
                dismiss(animated: true)
            }
            .store(in: &cancellables)
    }
}

class BannedAccountPopupViewController: AccountPopupViewController {}
class OutOfDataAccountPopupViewController: AccountPopupViewController {}
class ProPlanExpiredAccountPopupViewController: AccountPopupViewController {}

//
//  PrivacyPopUpViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 03/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class PrivacyPopUpViewController: BasePopUpViewController {
    var privacyViewModel: PrivacyViewModelType!
    var button = WSPillButton()
    var closeCompletion: (() -> Void)?

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Privacy Popup View")
        bindViews()
    }

    // MARK: Setting up

    override func setup() {
        super.setup()
        button.setTitle(TextsAsset.PrivacyView.action, for: .normal)
        button.setup(withHeight: 82)
        mainStackView.addArrangedSubview(button)
        titleLabel?.text = ""
        bodyLabel.font = UIFont.regular(size: 25)
    }

    private func bindViews() {
        button.rx.primaryAction.bind { [self] in
            logger.logD(self, "User tapped to accept privacy conditions.")
            self.privacyViewModel.action { self.closeCompletion?() }
            self.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
    }
}

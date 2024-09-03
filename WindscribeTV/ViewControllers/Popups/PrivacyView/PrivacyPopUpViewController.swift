//
//  PrivacyPopUpViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 03/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class PrivacyPopUpViewController: BasePopUpViewController {
    var privacyViewModel: PrivacyViewModelType!
    var button = WSPillButton()

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViews()
    }

    // MARK: Setting up
    override func setup() {
        super.setup()
        button.setTitle(TextsAsset.PrivacyView.action, for: .normal)
        button.setup(withHeight: 96.0)
        mainStackView.addArrangedSubview(button)
        mainStackView.addArrangedSubview(UIView())
    }

    private func bindViews() {
        button.rx.primaryAction.bind { [self] in
            self.privacyViewModel.action()
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}

//
//  GhostAccountViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-20.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class GhostAccountViewController: WSNavigationViewController {
    // MARK: - State properties

    var viewModel: GhostAccountViewModelType?
    var router: GhostAccountRouter?
    var logger: FileLogger!

    var infoLabel: UILabel!
    var loginButton: UIButton!
    var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Ghost Account View")
        addViews()
        addAutoLayoutConstraints()
        titleLabel.text = TextsAsset.Preferences.account
        infoLabel.text = TextsAsset.Account.ghostInfo
        signUpButton.setTitle(TextsAsset.signUp, for: .normal)
        loginButton.setTitle(TextsAsset.login, for: .normal)
        bindData()
    }

    private func bindData() {
        signUpButton.rx.tap.bind { [self] in
            if self.viewModel?.isUserPro() ?? false {
                router?.routeTo(to: RouteID.signup(claimGhostAccount: true), from: self)
            } else {
                router?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: self)
            }
        }.disposed(by: disposeBag)

        viewModel?.isDarkMode.subscribe {
            self.setupViews(isDark: $0)
            self.infoLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.signUpButton.setTitleColor(ThemeUtils.primaryTextColorInvert(isDarkMode: $0), for: .normal)
            self.loginButton.setTitleColor(ThemeUtils.primaryTextColor(isDarkMode: $0), for: .normal)
        }.disposed(by: disposeBag)

        loginButton.rx.tap.bind { [self] in
            router?.routeTo(to: RouteID.login, from: self)
        }.disposed(by: disposeBag)
    }
}

//
//  WelcomeViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2020-12-08.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import AVKit
import RxSwift
import UIKit

class WelcomeViewController: WSUIViewController {
    // MARK: - UI properties

    var backgroundView: UIView!
    var logoButton: UIButton!
    var backgroundImageView, bottomGradientView: UIImageView!
    var continueButton, loginButton, emergencyConnect: UIButton!
    var signUpInfoLabel: UILabel!
    var sloganLabel: UILabel!
    var loadingView: UIActivityIndicatorView!
    var pageControl: UIPageControl!
    var infoLabel1, infoLabel2, infoLabel3, infoLabel4: UILabel!
    var scrollView: UIScrollView!

    // MARK: - State properties

    var router: WelcomeRouter!, viewmodal: WelcomeViewModal!, logger: FileLogger!
    var scrollOrder = 0
    var slideTimer: Timer?

    // MARK: - UI Events

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13.0, *) {
            for window in UIApplication.shared.windows {
                window.overrideUserInterfaceStyle = .dark
            }
        }
        setupLocalized()
    }

    override func setupLocalized() {
        sloganLabel.text = TextsAsset.slogan
        continueButton.setTitle(TextsAsset.getStarted, for: .normal)
        infoLabel1.text = TextsAsset.Powers.first
        infoLabel2.text = TextsAsset.Powers.second
        infoLabel3.text = TextsAsset.Powers.third
        infoLabel4.text = TextsAsset.Powers.fourth
        loginButton.setTitle(TextsAsset.login, for: .normal)
    }

    // MARK: - Setup and Bind views

    private func setupViews() {
        configureViews()
        addAutoLayoutConstraints()
        slideTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(slideScrollView), userInfo: nil, repeats: true)
    }

    private func bindViews() {
        viewmodal.showLoadingView.bind { [self] show in
            if show {
                showLoadingView()
            } else {
                hideLoadingView()
            }
        }.disposed(by: disposeBag)
        loginButton.rx.tap.bind { [self] in
            router.routeTo(to: RouteID.login, from: self)
        }.disposed(by: disposeBag)
        viewmodal.routeToSignup.bind { [self] _ in
            router.routeTo(to: RouteID.signup(claimGhostAccount: false), from: self)
        }.disposed(by: disposeBag)
        viewmodal.routeToMainView.bind { [self] _ in
            router.routeTo(to: RouteID.home, from: self)
        }.disposed(by: disposeBag)
        continueButton.rx.tap.bind { [self] in
            viewmodal.continueButtonTapped()
        }.disposed(by: disposeBag)
        emergencyConnect.rx.tap.bind { [self] in
            router.routeTo(to: RouteID.emergency, from: self)
        }.disposed(by: disposeBag)
        viewmodal.emergencyConnectStatus.bind { [weak self] active in
            if active {
                self?.emergencyConnect.setBackgroundImage(UIImage(named: ImagesAsset.emergencyConnectOn), for: .normal)
            } else {
                self?.emergencyConnect.setBackgroundImage(UIImage(named: ImagesAsset.emergencyConnectOff), for: .normal)
            }
        }.disposed(by: disposeBag)
    }
}

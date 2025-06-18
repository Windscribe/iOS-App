//
//  WelcomeViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 09/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class WelcomeViewController: UIViewController {
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var getStartedButton: WSRoundButton!
    @IBOutlet var loginButton: WSRoundButton!
    @IBOutlet var loginDescription: UILabel!
    @IBOutlet var containerView: UIView!
    var loadingView: UIActivityIndicatorView!

    // MARK: - State properties

    var router: WelcomeRouter!, viewmodal: WelcomeViewModel!, logger: FileLogger!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Welcome Screen.")
        setup()
        bindViews()
        setupLocalized()
        // Do any additional setup after loading the view.
    }

    func setup() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            view.backgroundColor = .blue
        }
        welcomeLabel.font = UIFont.bold(size: 60)
        loginDescription.font = UIFont.text(size: 30)
        loginDescription.textColor = .whiteWithOpacity(opacity: 0.50)
        loginDescription.isHidden = true
        containerView.backgroundColor = .midnightWithOpacity(opacity: 0.90)

        loadingView = UIActivityIndicatorView(style: .large)
        loadingView.isHidden = true
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        ])

        loginButton.hasBorder = true
        getStartedButton.hasBorder = true
    }

    func setupLocalized() {
        loginButton.setTitle(TextsAsset.login.uppercased(), for: .normal)
        welcomeLabel.text = TextsAsset.slogan
        loginDescription.text = TextsAsset.TVAsset.welcomeDescription
        getStartedButton.setTitle(TextsAsset.getStarted.uppercased(), for: .normal)
    }

    private func bindViews() {
        viewmodal.showLoadingView.bind { [self] show in
            if show {
                showLoadingView()
            } else {
                hideLoadingView()
            }
        }.disposed(by: disposeBag)
        loginButton.rx.primaryAction.bind { [self] in
            router.routeTo(to: RouteID.login, from: self)
        }.disposed(by: disposeBag)
        viewmodal.routeToSignup.bind { [self] _ in
            DispatchQueue.main.async {
                self.router.routeTo(to: RouteID.signup(claimGhostAccount: false), from: self)
            }
        }.disposed(by: disposeBag)
        viewmodal.routeToMainView.bind { [self] _ in
            router.routeTo(to: RouteID.home, from: self)
        }.disposed(by: disposeBag)
        getStartedButton.rx.primaryAction.bind { [self] in
            viewmodal.continueButtonTapped()
        }.disposed(by: disposeBag)
    }

    func hideLoadingView() {
        loadingView.isHidden = true
    }

    func showLoadingView() {
        loadingView.startAnimating()
        loadingView.isHidden = false
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if context.nextFocusedView === loginButton {
            loginDescription.isHidden = false
        } else {
            loginDescription.isHidden = true
        }
    }
}

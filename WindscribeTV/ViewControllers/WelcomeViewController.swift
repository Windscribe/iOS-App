//
//  WelcomeViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 09/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class WelcomeViewController: UIViewController {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var getStartedButton: WSRoundButton!
    @IBOutlet weak var loginButton: WSRoundButton!
    @IBOutlet weak var loginDescription: UILabel!
    @IBOutlet weak var containerView: UIView!
    var loadingView: UIActivityIndicatorView!

    // MARK: - State properties
    var router: WelcomeRouter!, viewmodal: WelcomeViewModal!, logger: FileLogger!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
        // Do any additional setup after loading the view.
    }

    func setup() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            self.view.backgroundColor = .blue
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
        self.view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0)
        ])

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
            router.routeTo(to: RouteID.signup(claimGhostAccount: false), from: self)
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

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView === loginButton {
            loginDescription.isHidden = false
        } else {
            loginDescription.isHidden = true
        }
    }

}

//
//  WelcomeViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 09/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
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
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
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
        viewmodal.showLoadingView
            .sink { [self] show in
                if show {
                    showLoadingView()
                } else {
                    hideLoadingView()
                }
            }
            .store(in: &cancellables)
        loginButton.wasSelected
            .sink { [self] _ in
                router.routeTo(to: RouteID.login, from: self)
            }
            .store(in: &cancellables)
        viewmodal.routeToSignup
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                self.router.routeTo(to: RouteID.signup(claimGhostAccount: false), from: self)
            }
            .store(in: &cancellables)
        viewmodal.routeToMainView
            .sink { [self] _ in
                router.routeTo(to: RouteID.home, from: self)
            }
            .store(in: &cancellables)
        getStartedButton.wasSelected
            .sink { [self] _ in
                viewmodal.continueButtonTapped()
            }
            .store(in: &cancellables)
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

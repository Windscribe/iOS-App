//
//  UIViewController+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-27.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import SafariServices
import Swinject
import RxSwift

class WSUIViewController: UIViewController {
    var splashView: LoadingSplashView?
    var promptBackgroundView: PromptBackgroundView!

    // loading views
    var loadingBackgroundView: UIView!
    var backgroundLoadingIndicator: UIActivityIndicatorView!

    // getmoredata views
    var getMoreDataView: UIImageView!
    var getMoreDataLabel: UILabel!
    var getMoreDataButton: UIButton!

    // layoutView
    lazy var layoutView: WSFillLayoutView = {
        let layoutView = WSFillLayoutView()
        return layoutView
    }()

    lazy var apiManager = Assembler.resolve(APIManager.self)
    lazy var sessionManager = Assembler.resolve(SessionManagerV2.self)
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(displayLeftDataInformation), name: Notifications.sessionUpdated, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "didChangeLangeguage"), object: nil, queue: .main) { [weak self] _ in
            self?.setupLocalized()
        }
    }

    func setupLocalized() {

    }

    @objc func displayLeftDataInformation() {
        if getMoreDataLabel == nil { return }
        guard let session = sessionManager.session else { return }
        getMoreDataLabel.text = "\(session.getDataLeft()) \(TextsAsset.left.uppercased())"
        if session.isUserPro {
            getMoreDataView.isHidden = true
            getMoreDataLabel.isHidden = true
            getMoreDataButton.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        setupLocalized()
    }

    func showSplashView() {
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(hideSplashView), userInfo: nil, repeats: false)
        self.splashView = LoadingSplashView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(splashView!)
        self.view.bringSubviewToFront(splashView!)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.splashView?.updateSize(size: size)
    }

    @objc func hideSplashView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.splashView?.layer.opacity = 0.1
            }, completion: { _ in
                self.splashView?.removeFromSuperview()
                NotificationCenter.default.post(Notification(name: Notifications.configureBestLocation))
            })
        }
    }

    func openLink(url: String) {
        guard let urlValue =  URL(string: url) else { return }
        openLink(url: urlValue)
    }

    func openLink(url: URL) {
       let safariVC = SFSafariViewController(url: url)
       safariVC.preferredBarTintColor = UIColor.black
       self.present(safariVC, animated: true, completion: nil)
       safariVC.delegate = self
    }

    func showLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.loadingBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            self.loadingBackgroundView.backgroundColor = UIColor.black
            self.loadingBackgroundView.layer.opacity = 0.5

            self.backgroundLoadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
            self.backgroundLoadingIndicator.startAnimating()
            self.backgroundLoadingIndicator.frame = CGRect(x: UIScreen.main.bounds.width/2-25, y: UIScreen.main.bounds.height/2-25, width: 50, height: 50)

            UIView.transition(with: self.view,
                              duration: 0.25,
                              options: [.transitionCrossDissolve],
                              animations: { [weak self] in
                guard let self = self else {
                    return
                }

                self.view.addSubview(self.loadingBackgroundView)
                self.view.addSubview(self.backgroundLoadingIndicator)
            }, completion: nil)
        }
    }

    func endLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            UIView.transition(with: self.view,
                              duration: 0.25,
                              options: [.transitionCrossDissolve],
                              animations: { [weak self] in
                if self?.backgroundLoadingIndicator != nil && self?.loadingBackgroundView != nil {
                    self?.backgroundLoadingIndicator.removeFromSuperview()
                    self?.loadingBackgroundView.removeFromSuperview()
                }
            }, completion: nil)
        }
    }

    @objc func getMoreDataButtonTapped() {
        let vc = Assembler.resolve(UpgradeViewController.self)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func addPromptBackgroundView() {
        promptBackgroundView = PromptBackgroundView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        promptBackgroundView.layer.opacity = 0.0
        self.view.addSubview(promptBackgroundView)
    }

    func showPromptBackgroundView() {
        UIView.transition(with: promptBackgroundView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.promptBackgroundView.layer.opacity = 1.0
        }, completion: nil)
    }

    @objc func hidePromptBackgroundView() {
        UIView.transition(with: promptBackgroundView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.promptBackgroundView.layer.opacity = 0.0
        }, completion: nil)
    }

    func setupFillLayoutView() {
        view.addSubview(layoutView)
        layoutView.fillSuperviewSafeAreaLayoutGuide()
    }
}

extension WSUIViewController: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
        apiManager.getSession(nil).subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
    }

}

class WSNavigationViewController: WSUIViewController {

    override func setupFillLayoutView() {
        view.addSubview(layoutView)
        layoutView.anchor(top: titleLabel.bottomAnchor,
                          left: view.leftAnchor,
                          bottom: view.bottomAnchor,
                          right: view.rightAnchor)
    }

    var backButton: LargeTapAreaImageButton!
    var closeButton: LargeTapAreaImageButton?
    var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        backButton = LargeTapAreaImageButton()
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)

        titleLabel = UILabel()
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
    }

    open func setupCloseButton() {
        backButton.isHidden = true

        let closeButton = LargeTapAreaImageButton()
        closeButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.anchor(
            top: view.topAnchor,
            right: view.rightAnchor,
            paddingTop: UIScreen.hasTopNotch ? 70 : 32,
            paddingRight: 16,
            width: 32, height: 32
        )
        self.closeButton = closeButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func viewDidLayoutSubviews() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                NSLayoutConstraint(item: backButton as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 70)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: backButton as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 32)
                ])
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: backButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: backButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: backButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 32)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: titleLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.backButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32)
            ])
    }

    @objc func backButtonTapped() {
        let viewControllerStack = navigationController?.viewControllers.count
        if viewControllerStack != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true) {}
        }
        HapticFeedbackGenerator.shared.run(level: .medium)
    }

    func setupViews(isDark: Bool) {
        view.backgroundColor = ThemeUtils.backgroundColor(isDarkMode: isDark)
        titleLabel.textColor = ThemeUtils.backgroundColor(isDarkMode: !isDark)
        backButton.setImage(UIImage(named: ThemeUtils.backButtonAsset(isDarkMode: isDark)), for: .normal)
        closeButton?.setImage(UIImage(named: ThemeUtils.closeButtonAsset(isDarkMode: isDark)), for: .normal)

        if #available(iOS 13.0, *) {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = ThemeUtils.interfaceStyle(isDarkMode: isDark)
            }
        }
    }
}

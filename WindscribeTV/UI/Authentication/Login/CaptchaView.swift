//
//  CaptchaPopupView.swift
//  WindscribeTV
//
//  Created by Soner Yuksel on 2025-12-17.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CaptchaView: UIView {

    // MARK: - UI Components

    private let containerView = UIView()
    private let captchaImageView = UIImageView()
    private let refreshButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let codeTextField = CaptchaCodeTextField()
    private let verifyButton = UIButton(type: .custom)
    private let backButton = UIButton(type: .custom)
    private let loadingView = UIActivityIndicatorView(style: .large)

    // MARK: - Public Observables

    let submitTap = PublishSubject<String>()
    let cancelTap = PublishSubject<Void>()
    let refreshTap = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Bindings

    func bind(to viewModel: CaptchaViewModel) {
        viewModel.captchaImage
            .observe(on: MainScheduler.instance)
            .bind(to: captchaImageView.rx.image)
            .disposed(by: disposeBag)

        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingView.startAnimating()
                } else {
                    self?.loadingView.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

        verifyButton.addTarget(self, action: #selector(didTapVerify), for: .primaryActionTriggered)
        backButton.addTarget(self, action: #selector(didTapBack), for: .primaryActionTriggered)
        refreshButton.addTarget(self, action: #selector(didTapRefresh), for: .primaryActionTriggered)
    }

    // MARK: - Actions

    @objc private func didTapVerify() {
        submitTap.onNext(codeTextField.text ?? "")
    }

    @objc private func didTapBack() {
        cancelTap.onNext(())
    }

    @objc private func didTapRefresh() {
        refreshTap.onNext(())
    }

    // MARK: - UI Setup

    private func setupUI() {
        backgroundColor = .clear

        // Container view (the modal popup)
        containerView.backgroundColor = UIColor(red: 15/255, green: 18/255, blue: 26/255, alpha: 1.0)
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        addSubview(containerView)

        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(640)
            $0.height.equalTo(580)
        }

        // Code TextField
        codeTextField.placeholder = ""
        codeTextField.textAlignment = .center
        codeTextField.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        codeTextField.textColor = .white
        codeTextField.borderStyle = .none
        codeTextField.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        codeTextField.layer.cornerRadius = 22
        codeTextField.layer.masksToBounds = true
        codeTextField.tintColor = .white

        // Add left padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        codeTextField.leftView = paddingView
        codeTextField.leftViewMode = .always
        codeTextField.rightView = paddingView
        codeTextField.rightViewMode = .always

        containerView.addSubview(codeTextField)

        codeTextField.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.equalTo(520)
            $0.height.equalTo(65)
        }

        // Captcha Container (black background with rounded corners)
        let captchaContainer = UIView()
        captchaContainer.backgroundColor = .black
        captchaContainer.layer.cornerRadius = 8
        captchaContainer.clipsToBounds = true
        containerView.addSubview(captchaContainer)

        captchaContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(40)
            $0.leading.equalToSuperview().offset(60)  // FIXED LEFT OFFSET!
            $0.height.equalTo(180)
            $0.width.equalTo(435)
        }

        // Captcha Image (inside container with bigger top/bottom padding)
        captchaImageView.contentMode = .scaleToFill  // Stretch to fill, don't clip
        captchaImageView.backgroundColor = .clear
        captchaContainer.addSubview(captchaImageView)

        captchaImageView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(15)  // 15pt padding top/bottom
            $0.leading.trailing.equalToSuperview().inset(5)  // 5pt padding left/right
        }

        // Loading View (centered on captcha container)
        loadingView.color = .white
        loadingView.hidesWhenStopped = true
        containerView.addSubview(loadingView)

        loadingView.snp.makeConstraints {
            $0.center.equalTo(captchaContainer)
        }

        // Refresh Button (vertically CENTERED with captcha container, right-aligned)
        refreshButton.setImage(UIImage(named: ImagesAsset.TvAsset.refreshButton), for: .normal)
        refreshButton.backgroundColor = .clear
        containerView.addSubview(refreshButton)

        refreshButton.snp.makeConstraints {
            $0.centerY.equalTo(captchaContainer)  // CENTERED WITH CAPTCHA CONTAINER!
            $0.trailing.equalTo(codeTextField.snp.trailing)
            $0.width.height.equalTo(60)
        }

        // Title Label
        titleLabel.text = TextsAsset.TVAsset.captchaTitle
        titleLabel.textColor = .white
        titleLabel.font = UIFont.text(size: 24)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(captchaContainer.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
        }

        // Update text field top constraint
        codeTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
        }

        // Verify Button
        verifyButton.setTitle(TextsAsset.TVAsset.captchaAction, for: .normal)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.setTitleColor(.white, for: .focused)
        verifyButton.titleLabel?.font = UIFont.text(size: 24)
        verifyButton.backgroundColor = .clear
        verifyButton.layer.cornerRadius = 32
        verifyButton.layer.borderWidth = 2
        verifyButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        verifyButton.clipsToBounds = true
        containerView.addSubview(verifyButton)

        verifyButton.snp.makeConstraints {
            $0.top.equalTo(codeTextField.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(520)
            $0.height.equalTo(64)
        }

        // Back Button
        backButton.setTitle(TextsAsset.back, for: .normal)
        backButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        backButton.setTitleColor(.white, for: .focused)
        backButton.titleLabel?.font = UIFont.text(size: 24)
        backButton.backgroundColor = .clear
        containerView.addSubview(backButton)

        backButton.snp.makeConstraints {
            $0.top.equalTo(verifyButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
        }

        // Set initial focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    // MARK: - Focus Management

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        let isVerifyFocused = context.nextFocusedView === verifyButton
        let isBackFocused = context.nextFocusedView === backButton
        let isCodeFocused = context.nextFocusedView === codeTextField
        let isRefreshFocused = context.nextFocusedView === refreshButton

        coordinator.addCoordinatedAnimations {
            // Verify button focus
            if isVerifyFocused {
                self.verifyButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
                self.verifyButton.layer.borderColor = UIColor.clear.cgColor
                self.verifyButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } else {
                self.verifyButton.backgroundColor = .clear
                self.verifyButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
                self.verifyButton.transform = .identity
            }

            // Back button focus
            self.backButton.alpha = isBackFocused ? 1.0 : 0.6

            // Code text field focus
            self.codeTextField.backgroundColor = isCodeFocused
                ? UIColor.white.withAlphaComponent(0.25)
                : UIColor.white.withAlphaComponent(0.15)

            // Refresh button focus (only scale, no background)
            if isRefreshFocused {
                self.refreshButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                self.refreshButton.transform = .identity
            }
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [codeTextField]
    }
}

// MARK: - Custom TextField

class CaptchaCodeTextField: UITextField {
    override var canBecomeFocused: Bool { true }
}

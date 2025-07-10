//
//  CaptchaView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-06-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CaptchaView: UIView {

    private let asciiImageView = UIImageView()
    private let titleLabel = UILabel()
    private let codeTextField = CaptchaCodeTextField()
    private let submitButton = UIButton(type: .custom)
    private let backButton = UIButton(type: .custom)

    let submitTap = PublishSubject<String>()
    let cancelTap = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Bindings
    func bind(to viewModel: CaptchaViewModel) {
        viewModel.captchaImage
            .observe(on: MainScheduler.instance)
            .bind(to: asciiImageView.rx.image)
            .disposed(by: disposeBag)

        submitButton.addTarget(self, action: #selector(didTapSubmit), for: .primaryActionTriggered)
        backButton.addTarget(self, action: #selector(didTapBack), for: .primaryActionTriggered)
    }

    @objc private func didTapSubmit() {
        submitTap.onNext(codeTextField.text ?? "")
    }

    @objc private func didTapBack() {
        cancelTap.onNext(())
    }

    // MARK: Layout Setup
    private func setupUI() {
        backgroundColor = .black

        // 1. LEFT SIDE BACKGROUND IMAGE
        let leftBackgroundView = UIImageView()
        leftBackgroundView.contentMode = .scaleAspectFill
        leftBackgroundView.image = UIImage(named: "WelcomeBackground")
        leftBackgroundView.clipsToBounds = true
        addSubview(leftBackgroundView)

        leftBackgroundView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.66)
        }

        // 2. ASCII IMAGE VIEW (centered inside left)
        asciiImageView.contentMode = .scaleAspectFit
        asciiImageView.backgroundColor = .black
        asciiImageView.layer.cornerRadius = 12
        asciiImageView.clipsToBounds = true
        addSubview(asciiImageView)

        asciiImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(149)
            $0.width.equalTo(980)
            $0.height.equalTo(457)
        }

        // 3. RIGHT PANEL
        let rightPanel = UIView()
        rightPanel.backgroundColor = UIColor(red: 2/255, green: 13/255, blue: 28/255, alpha: 1.0)
        addSubview(rightPanel)

        rightPanel.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(leftBackgroundView.snp.trailing)
        }

        // 4. Form elements in stack
        titleLabel.text = "Complete the Puzzle to Continue"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        codeTextField.placeholder = "Code"
        codeTextField.textAlignment = .left
        codeTextField.font = UIFont.boldSystemFont(ofSize: 30)
        codeTextField.textColor = UIColor.white.withAlphaComponent(0.5)
        codeTextField.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        codeTextField.layer.cornerRadius = 10
        codeTextField.clipsToBounds = true
        codeTextField.tintColor = .clear
        codeTextField.attributedPlaceholder = NSAttributedString(
            string: "Code",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.3),
                .font: UIFont.boldSystemFont(ofSize: 30)
            ]
        )

        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        submitButton.setTitleColor(.white, for: .focused)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 35)
        submitButton.setBackgroundImage(UIImage.imageWithColor(UIColor.white.withAlphaComponent(0.25)), for: .focused)
        submitButton.setBackgroundImage(UIImage.imageWithColor(.clear), for: .normal)
        submitButton.layer.cornerRadius = 75 / 2
        submitButton.layer.borderWidth = 2
        submitButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        submitButton.clipsToBounds = true

        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.lightGray, for: .normal)
        backButton.setTitleColor(.white, for: .focused)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 35)
        backButton.backgroundColor = .clear

        let controlStack = UIStackView(arrangedSubviews: [titleLabel, codeTextField, submitButton, backButton])
        controlStack.axis = .vertical
        controlStack.spacing = 40
        controlStack.alignment = .center

        rightPanel.addSubview(controlStack)

        controlStack.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(450)
        }

        codeTextField.snp.makeConstraints { $0.height.equalTo(75); $0.width.equalToSuperview() }
        submitButton.snp.makeConstraints { $0.height.equalTo(75); $0.width.equalToSuperview() }
        backButton.snp.makeConstraints { $0.height.equalTo(60); $0.width.equalToSuperview() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self.setNeedsFocusUpdate()
          self.updateFocusIfNeeded()
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        let isSubmitFocused = context.nextFocusedView === submitButton
        let isBackFocused = context.nextFocusedView === backButton
        let isCodeFocused = context.nextFocusedView === codeTextField

        coordinator.addCoordinatedAnimations {
            // Submit button (rounded, WS style)
            self.submitButton.backgroundColor = isSubmitFocused ? UIColor.white.withAlphaComponent(0.25) : .clear
            self.submitButton.setTitleColor(isSubmitFocused ? .white : UIColor.white.withAlphaComponent(0.5), for: .normal)
            self.submitButton.layer.borderColor = isSubmitFocused ? UIColor.clear.cgColor : UIColor.white.withAlphaComponent(0.5).cgColor

            // Back button
            self.backButton.setTitleColor(isBackFocused ? .white : UIColor.white.withAlphaComponent(0.5), for: .normal)

            // Code text field
            self.codeTextField.backgroundColor = isCodeFocused ? UIColor.white.withAlphaComponent(0.19) : UIColor.white.withAlphaComponent(0.1)
            self.codeTextField.textColor = isCodeFocused ? .white : UIColor.white.withAlphaComponent(0.5)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [codeTextField]
    }

}

class CaptchaCodeTextField: UITextField {
  override var canBecomeFocused: Bool { true }
}

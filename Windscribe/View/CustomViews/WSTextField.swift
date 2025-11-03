//
//  WSTextField.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import Swinject
import UIKit

class WSTextField: UITextField, UITextFieldDelegate {
    var bottomBorder: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        bottomBorder = UIView(frame: CGRect(x: 0, y: 54, width: UIScreen.main.bounds.width, height: 2))
        bottomBorder.backgroundColor = UIColor.white
        bottomBorder.layer.opacity = 0.05
        addSubview(bottomBorder)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        bottomBorder.layer.opacity = 1.0
        textField.layer.opacity = 1.0
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        bottomBorder.layer.opacity = 0.25
        textField.layer.opacity = 0.25
    }
}

class AuthenticationTextField: UITextField {
    let disposeBag = DisposeBag()
    fileprivate var cancellables = Set<AnyCancellable>()
    var padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 5)

    init(isDarkMode: CurrentValueSubject<Bool, Never>) {
        super.init(frame: .zero)
        layer.cornerRadius = 3
        clipsToBounds = true
        font = UIFont.text(size: 16)
        autocorrectionType = .no
        autocapitalizationType = .none
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    fileprivate func bindViews(isDarkMode: CurrentValueSubject<Bool, Never>) {
        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                guard let self = self else { return }
                self.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
                self.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDark)
            }
            .store(in: &cancellables)
    }
}

class PasswordTextField: AuthenticationTextField {
    lazy var showHidePasswordButton = ImageButton()

    override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }

    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if isSecureTextEntry, let text = text {
            self.text?.removeAll()
            insertText(text)
        }
        return success
    }

    override init(isDarkMode: CurrentValueSubject<Bool, Never>) {
        super.init(isDarkMode: isDarkMode)
        padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 55)
        isSecureTextEntry = true
        clearsOnBeginEditing = false
        clearsOnInsertion = false
        showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withRenderingMode(.alwaysTemplate), for: .normal)
        showHidePasswordButton.addTarget(self, action: #selector(showHidePasswordButtonTapped), for: .touchUpInside)
        addSubview(showHidePasswordButton)
    }

    override func bindViews(isDarkMode: CurrentValueSubject<Bool, Never>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.showHidePasswordButton.tintColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            }
            .store(in: &cancellables)
    }

    @objc func showHidePasswordButtonTapped() {
        if isSecureTextEntry {
            isSecureTextEntry = false
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            isSecureTextEntry = true
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        showHidePasswordButton.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: showHidePasswordButton,
                               attribute: .centerY,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .centerY,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: showHidePasswordButton,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: -16),
            NSLayoutConstraint(item: showHidePasswordButton,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 24),
            NSLayoutConstraint(item: showHidePasswordButton,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .width,
                               multiplier: 1.0,
                               constant: 24)
        ])
    }
}

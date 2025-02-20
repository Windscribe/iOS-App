//
//  WSTextField.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

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

class LoginTextField: UITextField {
    let disposeBag = DisposeBag()
    var padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 5)

    init(isDarkMode: BehaviorSubject<Bool>) {
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

    fileprivate func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: {
            self.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }
}

class PasswordTextField: LoginTextField {
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

    override init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(isDarkMode: isDarkMode)
        padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 55)
        isSecureTextEntry = true
        clearsOnBeginEditing = false
        clearsOnInsertion = false
        showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withRenderingMode(.alwaysTemplate), for: .normal)
        showHidePasswordButton.addTarget(self, action: #selector(showHidePasswordButtonTapped), for: .touchUpInside)
        addSubview(showHidePasswordButton)
    }

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: {
            self.showHidePasswordButton.tintColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
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

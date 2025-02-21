//
//  UITextField+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UITextField {
    func setBottomBorder(opacity: Float) {
        borderStyle = .none
        layer.masksToBounds = false
        layer.backgroundColor = UIColor.white.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        layer.shadowOpacity = opacity
        layer.shadowRadius = 0.0
    }
}

class WSTextFieldTv: UITextField {
    lazy var textLayer = CATextLayer()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.backgroundColor = UIColor.clear.cgColor

        textLayer.font = font
        textLayer.foregroundColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        textLayer.alignmentMode = .justified
        textLayer.bounds = CGRect(x: -10, y: -10, width: layer.bounds.width - 10, height: layer.bounds.height - 10)
        backgroundColor = .clear
        textColor = .whiteWithOpacity(opacity: 0.50)
        font = UIFont.bold(size: 30)
        layer.cornerRadius = 10
        clipsToBounds = true
        tintColor = .clear
        layer.addSublayer(textLayer)
    }
}

class PasswordTextFieldTv: UITextField, UITextFieldDelegate {
    lazy var showHidePasswordButton = ImageButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    var showingPassword: Bool = false
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

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        isSecureTextEntry = true
        clearsOnBeginEditing = false
        clearsOnInsertion = false
        delegate = self
        showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withTintColor(.whiteWithOpacity(opacity: 0.50)), for: .normal)
        showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withTintColor(.whiteWithOpacity(opacity: 1.0)), for: .focused)
        showHidePasswordButton.addTarget(self, action: #selector(showHidePasswordButtonTapped), for: .primaryActionTriggered)
        super.addSubview(showHidePasswordButton)

        backgroundColor = .clear
        textColor = .whiteWithOpacity(opacity: 0.50)
        font = UIFont.bold(size: 30)
        layer.cornerRadius = 10
        clipsToBounds = true
        tintColor = .clear
        layer.backgroundColor = isFocused ? UIColor.whiteWithOpacity(opacity: 0.19).cgColor : UIColor.clear.cgColor
    }

    @objc func showHidePasswordButtonTapped() {
        showingPassword = true
        if isSecureTextEntry {
            isSecureTextEntry = false
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withTintColor(.whiteWithOpacity(opacity: 0.50)), for: .normal)
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withTintColor(.whiteWithOpacity(opacity: 1.0)), for: .focused)

        } else {
            isSecureTextEntry = true
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withTintColor(.whiteWithOpacity(opacity: 0.50)), for: .normal)
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withTintColor(.whiteWithOpacity(opacity: 1.0)), for: .focused)
        }
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
                               constant: 35),
            NSLayoutConstraint(item: showHidePasswordButton,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .width,
                               multiplier: 1.0,
                               constant: 35)
        ])
    }

    func textFieldShouldBeginEditing(_: UITextField) -> Bool {
        if showingPassword {
            showingPassword = false
            endEditing(true)

            return false
        }
        return true
    }
}

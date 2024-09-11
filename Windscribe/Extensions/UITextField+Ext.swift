//
//  UITextField.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UITextField {

    func setBottomBorder(opacity: Float) {
        self.borderStyle = .none
        self.layer.masksToBounds = false
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = 0.0
    }

}

class WSTextFieldTv: UITextField {

    lazy var textLayer = CATextLayer()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.backgroundColor = UIColor.clear.cgColor

        textLayer.font = self.font
        textLayer.foregroundColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        textLayer.alignmentMode = .justified
        textLayer.bounds = CGRect(x: -10, y: -10, width: layer.bounds.width - 10, height: layer.bounds.height - 10)
        self.backgroundColor = .clear
        self.textColor = .whiteWithOpacity(opacity: 0.50)
        self.font = UIFont.text(size: 30)
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        self.tintColor = .clear

        layer.addSublayer(textLayer)
    }

    override func layoutSublayers(of layer: CALayer) {
        layer.backgroundColor = self.isFocused ? UIColor.whiteWithOpacity(opacity: 0.19).cgColor : UIColor.clear.cgColor
        textLayer.frame = layer.bounds
        textLayer.string = self.text?.isEmpty ?? true ? self.placeholder : self.text
    }

    override func addSubview(_ view: UIView) {

        // blocks standard styling
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
          if isSecureTextEntry, let text = self.text {
              self.text?.removeAll()
              insertText(text)
          }
          return success
      }

     required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.isSecureTextEntry = true
        self.clearsOnBeginEditing = false
        self.clearsOnInsertion = false
         self.delegate = self
         showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withTintColor(.whiteWithOpacity(opacity: 0.50)), for: .normal)
         showHidePasswordButton.setImage(UIImage(named: ImagesAsset.hidePassword)?.withTintColor(.whiteWithOpacity(opacity: 1.0)), for: .focused)
        showHidePasswordButton.addTarget(self, action: #selector(showHidePasswordButtonTapped), for: .primaryActionTriggered)
        super.addSubview(showHidePasswordButton)

         self.backgroundColor = .clear
         self.textColor = .whiteWithOpacity(opacity: 0.50)
         self.font = UIFont.text(size: 30)
         self.layer.cornerRadius = 10
         self.clipsToBounds = true
         self.tintColor = .clear
         layer.backgroundColor = self.isFocused ? UIColor.whiteWithOpacity(opacity: 0.19).cgColor : UIColor.clear.cgColor

    }

    @objc func showHidePasswordButtonTapped() {
        showingPassword = true
        if self.isSecureTextEntry {
            self.isSecureTextEntry = false
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withTintColor(.whiteWithOpacity(opacity: 0.50)), for: .normal)
            showHidePasswordButton.setImage(UIImage(named: ImagesAsset.showPassword)?.withTintColor(.whiteWithOpacity(opacity: 1.0)), for: .focused)

        } else {
            self.isSecureTextEntry = true
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

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if showingPassword {
            showingPassword = false
            self.endEditing(true)

            return false }
        return true
    }

}

//
//  SettingOption.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol SettingOptionDelegate: NSObject {
    func optionWasSelected(with value: String)
}

class SettingOption: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var selectedImageView: UIImageView!
    private var button = UIButton()
    private var value: String = ""

    weak var delegate: SettingOptionDelegate?

    @IBAction func selectOption(_ sender: Any) {
        delegate?.optionWasSelected(with: value)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let scale = 1.1
        let translationX = titleLabel.frame.width * (scale - 1) / 2.0
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            UIView.animate(withDuration: 0.5) {
                self.titleLabel.transform = CGAffineTransformConcat(CGAffineTransform(scaleX: scale, y: scale), CGAffineTransform(translationX: translationX, y: -1))
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.titleLabel.transform = CGAffineTransformConcat(CGAffineTransform(scaleX: 1.0, y: 1.0), CGAffineTransform(translationX: 0, y: 0))
            }
        }
    }

    func setup(with title: String, isSelected: Bool = false) {
        value = title
        selectedView.layer.cornerRadius = 8
        selectedView.layer.borderWidth = 2
        selectedView.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        titleLabel.text = title
        titleLabel.alpha = 0.5
        updateSelection(with: isSelected)
        addSubview(button)
        button.addTarget(self, action: #selector(selectOption), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        button.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }

    func updateSelection(with isSelected: Bool) {
        selectedView.isHidden = !isSelected
        selectedImageView.isHidden = !isSelected
    }
}

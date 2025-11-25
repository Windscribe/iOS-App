//
//  SettingOption.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol SettingOptionDelegate: AnyObject {
    func optionWasSelected(with value: String)
}

class SettingOption: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var selectedView: UIView!
    @IBOutlet var buttonContainerView: UIStackView!
    @IBOutlet var selectedImageView: UIImageView!
    private var button = UIButton()
    private var value: String = ""
    private let borderWidth = 4.0

    weak var delegate: SettingOptionDelegate?

    @IBAction func selectOption(_: Any) {
        delegate?.optionWasSelected(with: value)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        var newColor = UIColor.clear
        var hasBorder = true
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            newColor = .whiteWithOpacity(opacity: 0.5)
            hasBorder = false
        }
        UIView.animate(withDuration: 0.2) {
            self.selectedView.backgroundColor = newColor
            self.selectedView.layer.borderWidth = hasBorder ? self.borderWidth : 0
        }
    }

    func setup(with title: String, isSelected: Bool = false) {
        value = title
        selectedView.layer.cornerRadius = 8
        selectedView.layer.borderWidth = borderWidth
        selectedView.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.5).cgColor
        titleLabel.text = title
        titleLabel.alpha = 0.5
        updateSelection(with: isSelected)
        buttonContainerView.addArrangedSubview(button)
        button.addTarget(self, action: #selector(selectOption), for: .primaryActionTriggered)
    }

    func updateTitle(with title: String) {
        value = title
        titleLabel.text = title
    }

    func updateSelection(with isSelected: Bool) {
        selectedImageView.isHidden = !isSelected
        selectedView.layer.borderColor = isSelected ? UIColor.whiteWithOpacity(opacity: 0.5).cgColor : UIColor.clear.cgColor
    }
}

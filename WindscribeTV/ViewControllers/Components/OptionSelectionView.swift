//
//  OptionSelectionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 22/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol OptionSelectionViewDelegate: AnyObject {
    func optionWasSelected(_ sender: OptionSelectionView)
}

class OptionSelectionView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var focusView: UIView!
    @IBOutlet weak var buttonHolder: UIStackView!
    var button = UIButton()
    
    weak var delegate: OptionSelectionViewDelegate?

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            UIView.animate(withDuration: 0.5) {
                self.focusView.isHidden = false            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.focusView.isHidden = true
            }
        }
    }

    func setup(with value: String, isSelected: Bool = false, isPrimary: Bool = false) {
        selectedView.layer.cornerRadius = 8
        titleLabel.text = value
        titleLabel.font = isPrimary ? UIFont.bold(size: 42) : UIFont.regular(size: 42)
        updateSelection(with: isSelected)
        focusView.isHidden = !isSelected
        buttonHolder.addArrangedSubview(button)
        button.addTarget(self, action: #selector(selectOption), for: .primaryActionTriggered)
        focusView.layoutIfNeeded()
        focusView.addGreyHGradientBackground()
        focusView.setNeedsDisplay()
        focusView.clipsToBounds = true
    }
    
    @IBAction func selectOption(_ sender: Any) {
        delegate?.optionWasSelected(self)
    }

    func updateSelection(with isSelected: Bool) {
        titleLabel.alpha = isSelected ? 1 : 0.5
        selectedView.isHidden = !isSelected
    }
}

//
//  PreferencesOptionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol PreferencesOptionViewDelegate: AnyObject {
    func optionWasSelected(with value: PreferencesType)
}

class PreferencesOptionView: UIView {
    private var optionType: PreferencesType?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    var button = UIButton()

    weak var delegate: PreferencesOptionViewDelegate?

    @IBAction func selectOption(_ sender: Any) {
        guard let optionType = optionType else {return}
        delegate?.optionWasSelected(with: optionType)
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

    func setup(with type: PreferencesType, isSelected: Bool = false) {
        optionType = type
        selectedView.layer.cornerRadius = 2
        titleLabel.text = type.rawValue
        titleLabel.font = type.isPrimary ? UIFont.bold(size: 42) : UIFont.regular(size: 42)
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
        titleLabel.alpha = isSelected ? 1 : 0.5
        selectedView.isHidden = !isSelected
    }

    func isType(of type: PreferencesType) -> Bool {
        return type == optionType
    }
}

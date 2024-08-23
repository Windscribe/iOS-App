//
//  PreferencesOptionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol PreferencesOptionViewDelegate: OptionSelectionViewDelegate {
    func optionWasSelected(with value: PreferencesType, _ sender: PreferencesOptionView)
}

class PreferencesOptionView: OptionSelectionView {
    private var optionType: PreferencesType?

    weak var selectionDelegate: PreferencesOptionViewDelegate?

    func setup(with type: PreferencesType, isSelected: Bool = false) {
        optionType = type
        super.setup(with: type.rawValue, isSelected: isSelected, isPrimary: type.isPrimary)
    }
    
    func updateTitle(with value: String? = nil) {
        if let value = value {
            titleLabel.text = value
        } else {
            titleLabel.text = optionType?.rawValue
        }
    }

    func isType(of type: PreferencesType) -> Bool {
        return type == optionType
    }
    
    @IBAction override func selectOption(_ sender: Any) {
        guard let optionType = optionType else {return}
        selectionDelegate?.optionWasSelected(with: optionType, self)
    }
}

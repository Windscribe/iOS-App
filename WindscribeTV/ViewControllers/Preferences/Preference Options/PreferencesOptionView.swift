//
//  PreferencesOptionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol PreferencesOptionViewDelegate: OptionSelectionViewDelegate {
    func optionWasSelected(with value: PreferencesType, _ sender: PreferencesOptionView)
}

class PreferencesOptionView: OptionSelectionView {
    var optionType: PreferencesType?
    private let disposeBag = DisposeBag()

    var viewModel: PreferencesMainViewModel?

    weak var selectionDelegate: PreferencesOptionViewDelegate?

    func setup(with type: PreferencesType, isSelected: Bool = false) {
        bindViews()
        optionType = type
        super.setup(with: type.title, isSelected: isSelected, isPrimary: type.isPrimary)
    }

    func updateTitle(with value: String? = nil) {
        if let value = value {
            titleLabel.text = value
        } else {
            titleLabel.text = optionType?.title
        }
    }

    func isType(of type: PreferencesType) -> Bool {
        return type == optionType
    }

    private func bindViews() {
        viewModel?.currentLanguage.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.updateTitle()
        }).disposed(by: disposeBag)
    }

    @IBAction override func selectOption(_ sender: Any) {
        guard let optionType = optionType else {return}
        selectionDelegate?.optionWasSelected(with: optionType, self)
    }
}

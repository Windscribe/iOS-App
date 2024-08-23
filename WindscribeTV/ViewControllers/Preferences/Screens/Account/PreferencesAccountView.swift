//
//  PreferencesAccountView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol PreferencesAccountViewDelegate: NSObject {
    func upgradeWasSelected()
}

class PreferencesAccountView: UIView {
    @IBOutlet weak var contentStackView: UIStackView!

    var viewModel: AccountViewModelType?
    var delegate: PreferencesAccountViewDelegate?

    func setup() {
        guard let accountViewModel = viewModel else { return }
        accountViewModel.getSections().forEach { section in
            let sectionView: AccountSectionView = AccountSectionView.fromNib()
            sectionView.setup(with: section)
            sectionView.delegate = self
            contentStackView.addArrangedSubview(sectionView)
        }
    }
}

extension PreferencesAccountView: AccountSectionViewDelegate {
    func upgradeWasSelected() {
        delegate?.upgradeWasSelected()
    }
}

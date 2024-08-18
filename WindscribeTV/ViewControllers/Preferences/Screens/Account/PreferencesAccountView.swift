//
//  PreferencesAccountView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class PreferencesAccountView: UIView {
    @IBOutlet weak var contentStackView: UIStackView!

    var viewModel: AccountViewModelType?

    func setup() {
        guard let accountViewModel = viewModel else { return }
        accountViewModel.getSections().forEach { section in
            let sectionView: AccountSectionView = AccountSectionView.fromNib()
            sectionView.setup(with: section)
//            itemView.delegate = self
            contentStackView.addArrangedSubview(sectionView)
        }
    }
}

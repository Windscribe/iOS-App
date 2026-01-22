//
//  PreferencesAccountView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit

protocol PreferencesAccountViewDelegate: AnyObject {
    func actionSelected(with item: AccountItemCell)
}

class PreferencesAccountView: UIView {
    @IBOutlet var contentStackView: UIStackView!

    var viewModel: AccountViewModelType?
    weak var delegate: PreferencesAccountViewDelegate?
    private var cancellables = Set<AnyCancellable>()

    func setup() {
        guard let accountViewModel = viewModel else { return }
        contentStackView.removeAllArrangedSubviews()
        for section in accountViewModel.getSections() {
            let sectionView: AccountSectionView = AccountSectionView.fromNib()
            sectionView.setup(with: section)
            sectionView.delegate = self
            contentStackView.addArrangedSubview(sectionView)
        }
    }

    func bindViews() {
        viewModel?.languageUpdatedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                for arrangedSubview in self.contentStackView.arrangedSubviews {
                    if let sectionView = arrangedSubview as? AccountSectionView {
                        sectionView.updateLocalisation()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

extension PreferencesAccountView: AccountSectionViewDelegate {
    func actionSelected(with item: AccountItemCell) {
        delegate?.actionSelected(with: item)
    }
}

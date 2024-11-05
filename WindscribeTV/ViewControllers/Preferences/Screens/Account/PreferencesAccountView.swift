//
//  PreferencesAccountView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

protocol PreferencesAccountViewDelegate: NSObject {
    func actionSelected(with item: AccountItemCell)
}

class PreferencesAccountView: UIView {
    @IBOutlet var contentStackView: UIStackView!

    var viewModel: AccountViewModelType?
    weak var delegate: PreferencesAccountViewDelegate?
    private let disposeBag = DisposeBag()

    func setup() {
        guard let accountViewModel = viewModel else { return }
        contentStackView.removeAllArrangedSubviews()
        for section in accountViewModel.getSections() {
            let sectionView = AccountSectionView.fromNib()
            sectionView.setup(with: section)
            sectionView.delegate = self
            contentStackView.addArrangedSubview(sectionView)
        }
    }

    func bindViews() {
        viewModel?.languageUpdatedTrigger.subscribe { [weak self] _ in
            guard let self = self else { return }
            for arrangedSubview in self.contentStackView.arrangedSubviews {
                if let sectionView = arrangedSubview as? AccountSectionView {
                    sectionView.updateLocalisation()
                }
            }
        }.disposed(by: disposeBag)
    }
}

extension PreferencesAccountView: AccountSectionViewDelegate {
    func actionSelected(with item: AccountItemCell) {
        delegate?.actionSelected(with: item)
    }
}

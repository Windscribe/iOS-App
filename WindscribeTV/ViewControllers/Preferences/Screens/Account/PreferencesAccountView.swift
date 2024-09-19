//
//  PreferencesAccountView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 05/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol PreferencesAccountViewDelegate: NSObject {
    func actionSelected(with item: AccountItemCell)
}

class PreferencesAccountView: UIView {
    @IBOutlet weak var contentStackView: UIStackView!

    var viewModel: AccountViewModelType?
    weak var delegate: PreferencesAccountViewDelegate?
    private let disposeBag = DisposeBag()

    func setup() {
        guard let accountViewModel = viewModel else { return }
        contentStackView.removeAllArrangedSubviews()
        accountViewModel.getSections().forEach { section in
            let sectionView: AccountSectionView = AccountSectionView.fromNib()
            sectionView.setup(with: section)
            sectionView.delegate = self
            contentStackView.addArrangedSubview(sectionView)
        }
    }

    func bindViews() {
        viewModel?.languageUpdatedTrigger.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.contentStackView.arrangedSubviews.forEach {
                if let sectionView = $0 as? AccountSectionView {
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

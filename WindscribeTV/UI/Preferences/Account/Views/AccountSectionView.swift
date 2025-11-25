//
//  AccountSectionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 07/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol AccountSectionViewDelegate: AnyObject {
    func actionSelected(with item: AccountItemCell)
}

class AccountSectionView: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var stackView: UIStackView!

    weak var delegate: AccountSectionViewDelegate?
    private var sectionData: AccountSectionItem?

    func setup(with sectionData: AccountSectionItem) {
        self.sectionData = sectionData
        titleLabel.textColor = .white.withAlphaComponent(0.5)
        titleLabel.attributedText = NSAttributedString(string: sectionData.title,
                                                       attributes: [
                                                           .font: UIFont.bold(size: 32),
                                                           .foregroundColor: UIColor.white.withAlphaComponent(0.3),
                                                           .kern: 4
                                                       ])

        for item in sectionData.items {
            let itemView: AccountItemView = AccountItemView.fromNib()
            itemView.setup(with: item)
            itemView.delegate = self
            stackView.addArrangedSubview(itemView)
        }
    }

    func updateLocalisation() {
        guard let sectionData = sectionData else { return }
        stackView.removeAllArrangedSubviews()
        setup(with: sectionData)
    }
}

extension AccountSectionView: AccountItemViewDelegate {
    func actionSelected(with item: AccountItemCell) {
        delegate?.actionSelected(with: item)
    }
}

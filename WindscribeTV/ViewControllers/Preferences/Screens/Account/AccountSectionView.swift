//
//  AccountSectionView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 07/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol AccountSectionViewDelegate: NSObject {
    func upgradeWasSelected()
}

class AccountSectionView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    var delegate: AccountSectionViewDelegate?

    func setup(with sectionData: AccountSectionItem) {
        titleLabel.textColor = .white.withAlphaComponent(0.5)
        titleLabel.attributedText = NSAttributedString(string: sectionData.title,
                                              attributes: [
                                                .font: UIFont.bold(size: 32),
                                                .foregroundColor: UIColor.white.withAlphaComponent(0.3),
                                                .kern: 4
                                              ])

        sectionData.items.forEach { item in
            let itemView: AccountItemView = AccountItemView.fromNib()
            itemView.setup(with: item)
            itemView.delegate = self
            stackView.addArrangedSubview(itemView)
        }
    }
}

extension AccountSectionView: AccountItemViewDelegate {
    func upgradeWasSelected() {
        delegate?.upgradeWasSelected()
    }
}

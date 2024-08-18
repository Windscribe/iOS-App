//
//  AccountItemView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 07/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class AccountItemView: UIStackView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    func setup(with item: AccountItemCell) {
        titleLabel.font = UIFont.bold(size: 42)
        titleLabel.textColor = .white.withAlphaComponent(1.0)
        valueLabel.font = UIFont.regular(size: 42)
        valueLabel.textColor = .white.withAlphaComponent(0.5)

        titleLabel.text = item.title
        valueLabel.attributedText = item.value
    }
}

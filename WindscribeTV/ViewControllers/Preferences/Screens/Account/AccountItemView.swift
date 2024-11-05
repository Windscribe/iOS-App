//
//  AccountItemView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 07/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol AccountItemViewDelegate: NSObject {
    func actionSelected(with item: AccountItemCell)
}

class AccountItemView: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var stackView: UIStackView!

    @IBOutlet var itemHeightConstraint: NSLayoutConstraint!
    @IBOutlet var maxTitleWidth: NSLayoutConstraint!

    let button = UIButton()

    weak var delegate: AccountItemViewDelegate?
    private var item: AccountItemCell?

    func setup(with item: AccountItemCell) {
        self.item = item
        titleLabel.font = UIFont.bold(size: 42)
        titleLabel.textColor = .white.withAlphaComponent(1.0)
        valueLabel.font = UIFont.regular(size: 42)
        valueLabel.textColor = .white.withAlphaComponent(0.5)

        titleLabel.text = item.title
        valueLabel.attributedText = item.value

        let fixedHeight = itemHeightConstraint.constant
        let newSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: fixedHeight))
        if newSize.width > maxTitleWidth.constant {
            itemHeightConstraint.constant = 128.0
            stackView.layoutIfNeeded()
        }

        if item.hasAction {
            addSubview(button)
            button.addTarget(self, action: #selector(selectUpgrade), for: .primaryActionTriggered)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            button.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            button.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        }
    }

    @IBAction func selectUpgrade(_: Any) {
        guard let item = item, let delegate = delegate else { return }
        delegate.actionSelected(with: item)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.isHidden = true
            }
        }
    }
}

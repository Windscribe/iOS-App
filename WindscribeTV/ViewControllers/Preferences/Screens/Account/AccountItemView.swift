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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    
    let button = UIButton()
    
    var delegate: AccountItemViewDelegate?
    private var item: AccountItemCell?

    func setup(with item: AccountItemCell) {
        self.item = item
        titleLabel.font = UIFont.bold(size: 42)
        titleLabel.textColor = .white.withAlphaComponent(1.0)
        valueLabel.font = UIFont.regular(size: 42)
        valueLabel.textColor = .white.withAlphaComponent(0.5)

        titleLabel.text = item.title
        valueLabel.attributedText = item.value
        
        backgroundView.isHidden = true
        backgroundView.addGreyHGradientBackground()
        
        if item.hasAction {
            addSubview(button)
            button.addTarget(self, action: #selector(selectUpgrade), for: .primaryActionTriggered)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            button.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            button.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            button.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        }
    }
    
    @IBAction func selectUpgrade(_ sender: Any) {
        guard let item = item, let delegate = delegate else { return }
        delegate.actionSelected(with: item)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.isHidden = false            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.isHidden = true
            }
        }
    }
}

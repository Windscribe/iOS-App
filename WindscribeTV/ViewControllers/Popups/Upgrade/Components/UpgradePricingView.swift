//
//  UpgradePricingView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 14/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
protocol UpgradePricingViewDelegate: NSObject {
    func pricingOptionWasSelected(plan: WindscribeInAppProduct?)
}

class UpgradePricingView: UIView {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    weak var delegate: UpgradePricingViewDelegate?
    var button = UIButton()
    var plan: WindscribeInAppProduct?
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let nextButton = context.nextFocusedItem as? UIButton else { return }
        UIView.animate(withDuration: 0.2) {
                if nextButton == self.button { self.selectButton() }
                else { self.deselectButton()  }
            }
    }
    
    func selectButton() {
        button.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.4)
        button.layer.borderColor = UIColor.clear.cgColor
        descriptionLabel.textColor = .seaGreen
        priceLabel.textColor = .seaGreen
    }
    
    func deselectButton() {
        button.backgroundColor = .clear
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.4).cgColor
        descriptionLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        priceLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
    }
    
    func setup(with description: String, and price: String, isSelected: Bool = false) {
        descriptionLabel.text = description.uppercased()
        priceLabel.text = price
        
        descriptionLabel.font = UIFont.bold(size: 32)
        priceLabel.font = UIFont.bold(size: 32)
        
        if isSelected { selectButton() }
        else { deselectButton() }
        
        let buttonHeight: CGFloat = 112.0
        button.layer.cornerRadius = buttonHeight / 2.0
        self.addSubview(button)
        button.sendToBack()
        button.addTarget(self, action: #selector(selectOption), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
    }
    
    @objc private func selectOption() {
        delegate?.pricingOptionWasSelected(plan: plan)
    }
}

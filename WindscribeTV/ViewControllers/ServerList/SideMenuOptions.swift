//
//  SideMenuOptions.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 18/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol SideMenuOptionViewDelegate: AnyObject {
    func optionWasSelected(with value: SideMenuType)
}

class SideMenuOptions: UIView {
    @IBOutlet var selectionView: UIView!
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    let gradient = CAGradientLayer()

    var sideMenuType: SideMenuType?
    var button = UIButton()
    weak var delegate: SideMenuOptionViewDelegate?

    func setup(with type: SideMenuType, isSelected: Bool = false) {
        sideMenuType = type
        selectionView.layer.cornerRadius = 2
        titleLabel.text = type.rawValue.localize()
        imgView.image = type.getImage(isSelected: isSelected)
        titleLabel.font = UIFont.bold(size: 42)
        updateSelection(with: isSelected)
        addSubview(button)
        button.addTarget(self, action: #selector(selectOption), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        button.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }

    @IBAction func selectOption(_: Any) {
        guard let sideMenuType = sideMenuType else { return }
        delegate?.optionWasSelected(with: sideMenuType)
    }

    func updateSelection(with isSelected: Bool) {
        titleLabel.alpha = isSelected ? 1 : 0.5
        selectionView.isHidden = !isSelected
        imgView.image = sideMenuType?.getImage(isSelected: isSelected)
    }

    func setHorizontalGradientBackground() {
        // Create a gradient layer
        gradient.colors = [
            UIColor.whiteWithOpacity(opacity: 0.16).cgColor,
            UIColor.whiteWithOpacity(opacity: 0).cgColor
        ]

        // Set the frame of the gradient layer to match the view's bounds
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        if layer.sublayers?.contains(gradient) ?? false {
            gradient.colors = [
                UIColor.clear.cgColor,
                UIColor.clear.cgColor
            ]
        } else {
            layer.insertSublayer(gradient, at: 0)
        }

        // Define the gradient colors (white to white with slight variations if needed)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            setHorizontalGradientBackground()
        } else {
            layer.sublayers?.remove(at: 0)
        }
    }

    func isType(of type: SideMenuType) -> Bool {
        return type == sideMenuType
    }
}

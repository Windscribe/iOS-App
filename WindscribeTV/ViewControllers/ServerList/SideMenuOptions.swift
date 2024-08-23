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
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    let gradient = CAGradientLayer()

    private var sideMenuType: SideMenuType?
    var button = UIButton()
    weak var delegate: SideMenuOptionViewDelegate?

    func setup(with type: SideMenuType, isSelected: Bool = false) {
        sideMenuType = type
        selectionView.layer.cornerRadius = 2
        titleLabel.text = type.rawValue
        imgView.image = type.getImage(isSelected: isSelected)
        titleLabel.font =  UIFont.bold(size: 42)
        updateSelection(with: isSelected)
        addSubview(button)
        button.addTarget(self, action: #selector(selectOption), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        button.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    @IBAction func selectOption(_ sender: Any) {
        guard let sideMenuType = sideMenuType else {return}
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
        self.layer.insertSublayer(gradient, at: 0)
         
         // Define the gradient colors (white to white with slight variations if needed)
     }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextButton = context.nextFocusedItem as? UIButton, nextButton == button {
            self.setHorizontalGradientBackground()
        } else {
            self.layer.sublayers?.remove(at: 0)
        }
    }
    
    func isType(of type: SideMenuType) -> Bool {
        return type == sideMenuType
    }

}

//
//  UITextField.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UITextField {

    func setBottomBorder(opacity: Float) {
        self.borderStyle = .none
        self.layer.masksToBounds = false
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = 0.0
    }

}

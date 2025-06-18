//
//  WSActionButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class WSActionButton: UIButton {
    func enable() {
        isEnabled = true
        backgroundColor = UIColor.seaGreen
        setTitleColor(UIColor.midnight, for: .normal)
        layer.borderWidth = 0
        layer.cornerRadius = 24
        clipsToBounds = true
        layer.opacity = 1.0
    }

    func disable() {
        isEnabled = false
        backgroundColor = UIColor.clear
        layer.borderWidth = 2
        setTitleColor(UIColor.white, for: .normal)
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 24
        clipsToBounds = true
        layer.opacity = 0.4
    }
}

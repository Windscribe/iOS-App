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
        self.isEnabled = true
        self.backgroundColor = UIColor.seaGreen
        self.setTitleColor(UIColor.midnight, for: .normal)
        self.layer.borderWidth = 0
        self.layer.cornerRadius = 24
        self.clipsToBounds = true
        self.layer.opacity = 1.0
    }

    func disable() {
        self.isEnabled = false
        self.backgroundColor = UIColor.clear
        self.layer.borderWidth = 2
        self.setTitleColor(UIColor.white, for: .normal)
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 24
        self.clipsToBounds = true
        self.layer.opacity = 0.4
    }

}

//
//  TopMaskGradientView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 20/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class TopMaskGradientView: UIView {
    var currentColor: CGColor = UIColor.nightBlue.cgColor {
        didSet {
            redrawGradient()
        }
    }

    func redrawGradient() {
        layoutIfNeeded()
        layer.sublayers = []
        let width = UIScreen.main.bounds.width
        let gradient = CAGradientLayer()
        gradient.colors = [currentColor, UIColor.clear.cgColor]
        gradient.locations = [0,0.6]
        gradient.frame = CGRect(x: 0, y: 0, width: width, height: frame.height)
        layer.insertSublayer(gradient, at: 0)
    }
}

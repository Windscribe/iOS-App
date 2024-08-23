//
//  UIVIew+Gradient.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 20/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

extension UIView {
    func addBlueGradientBackground() {
        let startColor = UIColor.startBlue.cgColor
        let endColor = UIColor.gray.cgColor
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [startColor, endColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.frame.width, height: self.frame.height)
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func addGreyHGradientBackground() {
        let startColor = UIColor.whiteWithOpacity(opacity: 0.2).cgColor
        let endColor = UIColor.clear.cgColor
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [startColor, endColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.frame.width, height: self.frame.height)
        self.layer.insertSublayer(gradient, at: 0)
    }
}

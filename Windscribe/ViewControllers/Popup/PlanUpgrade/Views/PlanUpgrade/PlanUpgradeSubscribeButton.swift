//
//  PlanUpgradeSubscribeButton.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-04.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class PlanUpgradeGradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.85, green: 0.83, blue: 1, alpha: 1).cgColor,
            UIColor(red: 0.86, green: 0.8, blue: 0.97, alpha: 1).cgColor,
            UIColor(red: 0.95, green: 0.89, blue: 0.94, alpha: 1).cgColor,
            UIColor(red: 0.85, green: 0.84, blue: 0.92, alpha: 1).cgColor,
            UIColor(red: 0.79, green: 0.89, blue: 0.95, alpha: 1).cgColor,
            UIColor(red: 0.76, green: 0.9, blue: 0.93, alpha: 1).cgColor,
            UIColor(red: 0.74, green: 0.93, blue: 0.93, alpha: 1).cgColor,
            UIColor(red: 0.76, green: 0.91, blue: 0.94, alpha: 1).cgColor,
            UIColor(red: 0.79, green: 0.87, blue: 0.95, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.05, 0.17, 0.38, 0.45, 0.51, 0.56, 0.59, 0.67, 0.76] as [NSNumber]
        gradientLayer.startPoint = CGPoint(x: 0.21, y: -2.86)
        gradientLayer.endPoint = CGPoint(x: 0.77, y: 4.21)
        gradientLayer.cornerRadius = 24
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func updateAppearance() {
        alpha = isEnabled ? 1.0 : 0.5
    }
}

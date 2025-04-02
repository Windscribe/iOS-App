//
//  PlanUpgradeStarsBackgroundView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import UIKit

class PlanUpgradeStarsBackgroundView: UIView {

    private var emitterLayer: CAEmitterLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEmitter()
    }

    private func setupEmitter() {
        backgroundColor = UIColor.planUpgradeBackground

        emitterLayer = CAEmitterLayer().then {
            $0.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
            $0.emitterSize = CGSize(width: bounds.width, height: bounds.height) // Cover entire view

            $0.emitterShape = .rectangle // Emit from anywhere inside
            $0.emitterMode = .surface // Spread stars randomly
        }

        let starImage = createStarImage(size: CGSize(width: 6, height: 6))

        let star = CAEmitterCell().then {
            $0.contents = starImage
            $0.birthRate = isRegularSizeClass ? 20 : 5 // Controls how often stars appear
            $0.lifetime = isRegularSizeClass ? 16.0 : 8.0 // Stars live longer
            $0.velocity = isRegularSizeClass ? 6 : 3 // Slow movement
            $0.velocityRange = 6 // Some move slightly faster/slower
            $0.scale = 0.07 // Base size of stars
            $0.scaleRange = 0.04 // Some stars appear slightly larger/smaller
            $0.alphaSpeed = -0.05 // Gradual fade-out

            // Make Stars Spawn All Over the Screen**
            $0.xAcceleration = CGFloat.random(in: -5...5) // Move left/right randomly
            $0.yAcceleration = CGFloat.random(in: -5...5) // Move up/down randomly

            // Allow stars to move in random directions
            $0.emissionLongitude = .pi * 2 // 360-degree movement
            $0.emissionRange = .pi * 2 // Spread out evenly
        }

        emitterLayer.emitterCells = [star]
        layer.addSublayer(emitterLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure the emitter covers the full screen when resizing
        emitterLayer.do {
            $0.emitterSize = CGSize(width: bounds.width, height: bounds.height)
            $0.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY) // Keep centered
        }
    }

    private func createStarImage(size: CGSize) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.setFill()
            path.fill()
        }
        return image.cgImage
    }
}

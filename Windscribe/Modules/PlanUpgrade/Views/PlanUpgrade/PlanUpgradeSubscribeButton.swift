//
//  PlanUpgradeSubscribeButton.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-04.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

class PlanUpgradeGradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    private let glareImageView = UIImageView(image: UIImage(named: ImagesAsset.Subscriptions.glare))
    private var animator: UIViewPropertyAnimator?

    private var animationStarted = false
    private var firstRun = true // Ensures there is no  delay only on the first animation

    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupGlareEffect()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
        setupGlareEffect()
    }

    private func setupGradient() {
        gradientLayer.colors = [
             UIColor(displayP3Red: 0xDB / 255.0, green: 0xD3 / 255.0, blue: 0xFF / 255.0, alpha: 1).cgColor, // #DBD3FF
             UIColor(displayP3Red: 0xDB / 255.0, green: 0xCD / 255.0, blue: 0xF7 / 255.0, alpha: 1).cgColor, // #DBCDF7
             UIColor(displayP3Red: 0xF1 / 255.0, green: 0xE4 / 255.0, blue: 0xEF / 255.0, alpha: 1).cgColor, // #F1E4EF
             UIColor(displayP3Red: 0xD8 / 255.0, green: 0xD7 / 255.0, blue: 0xEA / 255.0, alpha: 1).cgColor, // #D8D7EA
             UIColor(displayP3Red: 0xC9 / 255.0, green: 0xE2 / 255.0, blue: 0xF2 / 255.0, alpha: 1).cgColor, // #C9E2F2
             UIColor(displayP3Red: 0xC3 / 255.0, green: 0xE5 / 255.0, blue: 0xEE / 255.0, alpha: 1).cgColor, // #C3E5EE
             UIColor(displayP3Red: 0xBD / 255.0, green: 0xED / 255.0, blue: 0xED / 255.0, alpha: 1).cgColor, // #BDEDED
             UIColor(displayP3Red: 0xC1 / 255.0, green: 0xE8 / 255.0, blue: 0xEF / 255.0, alpha: 1).cgColor, // #C1E8EF
             UIColor(displayP3Red: 0xCA / 255.0, green: 0xDF / 255.0, blue: 0xF2 / 255.0, alpha: 1).cgColor  // #CADFF2
         ]
        gradientLayer.do {
          $0.locations = [0.05, 0.17, 0.38, 0.45, 0.51, 0.56, 0.59, 0.67, 0.76] as [NSNumber]
          $0.startPoint = CGPoint(x: 0.21, y: -2.86)
          $0.endPoint = CGPoint(x: 0.77, y: 4.21)
          $0.cornerRadius = 24
        }
        gradientLayer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)
        layer.insertSublayer(gradientLayer, at: 0)
      }
    private func setupGlareEffect() {
        glareImageView.contentMode = .scaleAspectFit
        glareImageView.alpha = 0.8
        addSubview(glareImageView)

        glareImageView.snp.makeConstraints {
            $0.width.equalToSuperview().multipliedBy(0.6)
            $0.height.equalToSuperview().multipliedBy(1.5)
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(-UIScreen.main.bounds.width)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func updateAppearance() {
        alpha = isEnabled ? 1.0 : 0.5

        if isEnabled {
            // Ensure layout is fully set before starting animation
            if bounds.width > 0 && !animationStarted {
                animationStarted = true
                startGlareAnimation()
            }
        }
    }

    private func startGlareAnimation() {
        let delay = firstRun ? 0.0 : 8.0
        firstRun = false

        // Ensure glare starts exactly at the left before moving
        glareImageView.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(-self.bounds.width * 0.6)
        }
        layoutIfNeeded() // Apply immediately before animation starts

        // Create a new animator each time
        animator = UIViewPropertyAnimator(duration: 2.0, curve: .easeInOut, animations: { [weak self] in
            guard let self = self else { return }

            // Move glare fully across the button
            self.glareImageView.snp.updateConstraints {
                $0.leading.equalToSuperview().offset(self.bounds.width)
            }
            self.layoutIfNeeded()
        })

        animator?.startAnimation(afterDelay: delay)
        animator?.addCompletion { [weak self] _ in
            self?.resetGlarePosition()
        }
    }

    private func resetGlarePosition() {
        // Ensure animator is properly stopped before resetting
        if let animator = animator, animator.state == .active {
            animator.stopAnimation(true)
        }

        glareImageView.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(-self.bounds.width * 0.6)
        }
        layoutIfNeeded() // Apply reset immediately

        startGlareAnimation()
    }
}

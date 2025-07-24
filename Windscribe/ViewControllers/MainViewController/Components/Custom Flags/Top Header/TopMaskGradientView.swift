//
//  TopMaskGradientView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 20/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class TopMaskGradientView: UIView {
    private let gradientDisconnected = CAGradientLayer()
    private let gradientConnected = CAGradientLayer()

    var isConnected: Bool = false {
        didSet {
            if oldValue != isConnected {
                animateGradientFade()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradients()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradients()
    }

    private func setupGradients() {
        layer.sublayers = []
        let width = UIScreen.main.bounds.width

        gradientDisconnected.colors = [UIColor.nightBlue.cgColor, UIColor.clear.cgColor]
        gradientDisconnected.locations = [0, 0.6]
        gradientDisconnected.frame = CGRect(x: 0, y: 0, width: width, height: frame.height)
        layer.insertSublayer(gradientDisconnected, at: 0)

        gradientConnected.colors = [UIColor.connectedBlue.cgColor, UIColor.clear.cgColor]
        gradientConnected.locations = [0, 1.2]
        gradientConnected.frame = CGRect(x: 0, y: 0, width: width, height: frame.height)
        layer.insertSublayer(gradientConnected, at: 1)

        gradientDisconnected.opacity = 1
        gradientConnected.opacity = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = UIScreen.main.bounds.width
        gradientDisconnected.frame = CGRect(x: 0, y: 0, width: width, height: frame.height)
        gradientConnected.frame = CGRect(x: 0, y: 0, width: width, height: frame.height)
    }

    func animateGradientFade() {
        let animationTime = 0.25
        func getfadeAnimation(isFadeIn: Bool) -> CABasicAnimation {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = isFadeIn ? 0 : 1
            fade.toValue = isFadeIn ? 1 : 0
            fade.duration = animationTime
            fade.fillMode = .forwards
            fade.isRemovedOnCompletion = false
            return fade
        }

        gradientDisconnected.add(getfadeAnimation(isFadeIn: !isConnected),
                                 forKey: isConnected ? "fadeOut" : "fadeIn")
        gradientConnected.add(getfadeAnimation(isFadeIn: isConnected),
                              forKey: isConnected ? "fadeIn" : "fadeOut")
    }
}

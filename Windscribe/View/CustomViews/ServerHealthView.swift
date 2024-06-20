//
//  ServerHealthView.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-12-14.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit
class ServerHealthView: UIProgressView {

    var health: Int? {
        didSet {
            updateHealth()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        progressViewStyle = .bar
        progress = 0
        progressTintColor = UIColor.blackWithOpacity(opacity: 0.0)
        trackTintColor = UIColor.blackWithOpacity(opacity: 0.0)
        transform = CGAffineTransform(scaleX: 1, y: 0.5)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func updateHealth() {
        if let currentHealth = health {
            let healthFloat = Float(currentHealth)/100
            progress = healthFloat
            progressTintColor = getColorFromHealth(health: healthFloat)
        }
    }

    func getColorFromHealth(health: Float) -> UIColor {
        if health < 0.60 {
            return UIColor.green
        } else if health < 0.89 {
            return UIColor.yellow
        } else {
            return UIColor.red
        }
    }

}

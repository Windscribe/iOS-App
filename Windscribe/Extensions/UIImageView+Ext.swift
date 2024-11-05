//
//  UIImageView+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-12.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = image?.withRenderingMode(.alwaysTemplate)
        image = templateImage
        tintColor = color
    }

    func rotate(_ degrees: CGFloat) {
        UIView.animate(withDuration: 0.25) {
            self.transform = CGAffineTransform(rotationAngle: degrees * (.pi / 180))
        }
    }
}

extension UIImageView {
    func lightMode() {
        setImageColor(color: .midnight)
    }

    func darkMode() {
        setImageColor(color: .white)
    }

    override func updateTheme(isDark: Bool) {
        if isDark { darkMode() } else { lightMode() }
    }
}

//
//  UIButton+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-20.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension UIButton {
    func addIcon(icon: String) {
        let icon = UIImage(named: icon)
        setImage(icon, for: .normal)
        imageView?.contentMode = .scaleAspectFit
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        imageView?.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8)
    }
}

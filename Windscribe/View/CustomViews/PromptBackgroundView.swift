//
//  PromptBackgroundView.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-13.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

class PromptBackgroundView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [UIColor.blackWithOpacity(opacity: 0.5).cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        self.layer.insertSublayer(gradient, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

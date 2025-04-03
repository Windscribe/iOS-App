//
//  TopNavBarHeader.swift
//  Windscribe
//
//  Created by Andre Fonseca on 20/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class TopNavBarHeader: UIView {
    var height: CGFloat {
        if UIScreen.hasTopNotch {
            return 104
        } else if UIDevice.current.isIpad {
            return 86
        }
        return 80
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.nightBlueOpacity(opacity: 0.3)
        loadPath()
    }

    func loadPath() {
        let width = UIScreen.main.bounds.width
        let startingCurveX = width - 162.0
        let finalCurveY = height - 60.5

        let path = UIBezierPath()
        path.move(to: CGPoint(x: -1, y: -1))
        path.addLine(to: CGPoint(x: -1, y: finalCurveY + 60.5))
        path.addLine(to: CGPoint(x: startingCurveX, y: finalCurveY + 60.5))
        path.addLine(to: CGPoint(x: startingCurveX + 6.54578, y: finalCurveY + 60.5))
        path.addCurve(to: CGPoint(x: startingCurveX + 35.0505, y: finalCurveY + 44.1277),
                      controlPoint1: CGPoint(x: startingCurveX + 18.2828, y: finalCurveY + 60.5),
                      controlPoint2: CGPoint(x: startingCurveX + 29.1365, y: finalCurveY + 54.2659))
        path.addLine(to: CGPoint(x: startingCurveX + 42.8461, y: finalCurveY + 30.7639))
        path.addCurve(to: CGPoint(x: startingCurveX + 95.5366, y: finalCurveY + 0.5),
                      controlPoint1: CGPoint(x: startingCurveX + 53.7779, y: finalCurveY + 12.0236),
                      controlPoint2: CGPoint(x: startingCurveX + 73.8409, y: finalCurveY + 0.5))
        path.addLine(to: CGPoint(x: startingCurveX + 162, y: finalCurveY + 0.5))
        path.addLine(to: CGPoint(x: startingCurveX + 162, y: -1))
        path.addLine(to: CGPoint(x: -1, y: -1))

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.whiteWithOpacity(opacity: 0.1).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 2.0

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath

        layer.addSublayer(shapeLayer)
        layer.mask = maskLayer
    }

    func redrawGradient() {
        layoutIfNeeded()
        layer.sublayers = []
        loadPath()
    }
}

//
//  CompletionCircleView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 23/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class CompletionCircleView: UIView {
    let lineWidth: CGFloat
    let radius: CGFloat

    init(lineWidth: CGFloat = 1, radius: CGFloat = 12) {
        self.lineWidth = lineWidth
        self.radius = radius
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var percentage: CGFloat? {
        didSet {
            self.setNeedsDisplay()
            self.backgroundColor = .clear
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let percentage = percentage else { return }

        let endAngle = (percentage * 0.02 - 1) * CGFloat.pi
        let center = radius
        let innerRadius = radius - lineWidth / 2
        var path = UIBezierPath(arcCenter: CGPoint(x: center, y: center), radius: innerRadius, startAngle: -CGFloat.pi, endAngle: endAngle, clockwise: true)
        getColorFromPercentage().setStroke()
        path.lineWidth = lineWidth
        path.stroke()
        path = UIBezierPath(arcCenter: CGPoint(x: center, y: center), radius: innerRadius, startAngle: endAngle, endAngle: -CGFloat.pi, clockwise: true)
        path.lineWidth = lineWidth
        UIColor.whiteWithOpacity(opacity: 0.2).setStroke()
        path.stroke()
    }

    func getColorFromPercentage() -> UIColor {
        guard let percentage = percentage else { return .red }
        if percentage < 20 {
            return .red
        } else if percentage < 40 {
            return .yellow
        } else {
            return .seaGreen
        }
    }
}

//
//  UIScrollView.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-21.
//  Copyright © 2020 Windscribe. All rights reserved.
//
import UIKit

extension UIScrollView {
    func scrollToView(view: UIView, animated: Bool) {
        if let origin = view.superview {
            let childStartPoint = origin.convert(view.frame.origin, to: self)
            scrollRectToVisible(CGRect(x: 0,
                                       y: childStartPoint.y,
                                       width: 1,
                                       height: frame.height),
                                animated: animated)
        }
    }

    func scrollToTop(animated: Bool) {
        let topOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(topOffset, animated: animated)
    }
}

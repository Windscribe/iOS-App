//
//  WScrollView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-06.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class WScrollView: UIScrollView, UIGestureRecognizerDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.state != .possible {
            return true
        }
        return false
    }
}

//
//  ImageButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-22.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UIButton {
    func extendedArea(by extraSize: CGFloat) -> CGRect {
        return CGRect(
            x: bounds.origin.x - extraSize / 2.0,
            y: bounds.origin.y - extraSize / 2.0,
            width: bounds.size.width + extraSize,
            height: bounds.size.height + extraSize
        )
    }
}

class ImageButton: UIButton {
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        return extendedArea(by: 10.0).contains(point)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LargeTapAreaImageButton: UIButton {
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        return extendedArea(by: 30.0).contains(point)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

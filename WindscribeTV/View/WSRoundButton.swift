//
//  WSRoundButton.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 23/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

@IBDesignable
class WSRoundButton: UIButton {
    @IBInspectable var hasBorder: Bool = false {
        didSet {
            setborder()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        layer.cornerRadius = frame.height / 2
        clipsToBounds = true
        setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        setTitleColor(.white, for: .focused)
        setBackgroundImage(UIImage.imageWithColor(.whiteWithOpacity(opacity: 0.25)), for: .focused)
        setBackgroundImage(UIImage.imageWithColor(.clear), for: .normal)
        titleLabel?.font = UIFont.bold(size: 35)
    }

    func setborder() {
        if hasBorder {
            layer.borderWidth = 2
            layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        }
    }

    func updateCorners(radius: CGFloat) {
        layer.cornerRadius = radius
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if hasBorder {
            if context.nextFocusedView == self {
                layer.borderColor = UIColor.clear.cgColor
            } else {
                layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
            }
        }
    }
}

class WSPillButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setup(withHeight: CGFloat) {
        layer.cornerRadius = withHeight / 2.0
        clipsToBounds = true
        updateDeselected()
        heightAnchor.constraint(equalToConstant: withHeight).isActive = true
        layoutIfNeeded()
    }

    func updateCorners(radius: CGFloat) {
        layer.cornerRadius = radius
    }

    private func updateSelected() {
        backgroundColor = UIColor.whiteWithOpacity(opacity: 0.4)
        layer.borderColor = UIColor.clear.cgColor
        setTitleColor(.seaGreen, for: .normal)
    }

    func updateDeselected() {
        backgroundColor = .clear
        layer.borderWidth = 4
        layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.4).cgColor
        setTitleColor(.whiteWithOpacity(opacity: 0.5), for: .normal)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self {
            updateSelected()
        } else {
            updateDeselected()
        }
    }
}

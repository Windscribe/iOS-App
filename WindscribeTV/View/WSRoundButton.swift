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
        self.layer.cornerRadius = self.frame.height/2
        self.clipsToBounds = true
        self.setTitleColor(.whiteWithOpacity(opacity: 0.50), for: .normal)
        self.setTitleColor(.white, for: .focused)
        self.setBackgroundImage(UIImage.imageWithColor(.whiteWithOpacity(opacity: 0.25)), for: .focused)
        self.setBackgroundImage(UIImage.imageWithColor(.clear), for: .normal)
        self.titleLabel?.font = UIFont.bold(size: 35)
    }

    func setborder() {
        if hasBorder {
            self.layer.borderWidth = 2
            self.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if hasBorder {
            if context.nextFocusedView == self {
                self.layer.borderColor = UIColor.clear.cgColor
            } else {
                self.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor

            }
        }
    }
}

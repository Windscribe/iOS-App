//
//  UIFont+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-18.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UIFont {
    static func bold(size: CGFloat) -> UIFont {
        return UIFont(name: "IBMPlexSans-Bold", size: size)!
    }

    static func text(size: CGFloat) -> UIFont {
        return UIFont(name: "IBMPlexSans-Text", size: size)!
    }

    static func eurostileExt(size: CGFloat) -> UIFont {
        return UIFont(name: "EurostileExt-Bla", size: size)!
    }

    static func regular(size: CGFloat) -> UIFont {
        return UIFont(name: "IBMPlexSans", size: size)!
    }
}

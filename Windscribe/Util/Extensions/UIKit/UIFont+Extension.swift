//
//  UIFont+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-18.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import SwiftUI

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

extension UIFont {

    static func bold(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Bold", textStyle: textStyle)
    }

    static func medium(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Medium", textStyle: textStyle)
    }

    static func semiBold(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Medium", textStyle: textStyle)
    }

    static func text(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Text", textStyle: textStyle)
    }

    static func regular(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Regular", textStyle: textStyle)
    }

    static func customPreferredFont(name: String, textStyle: UIFont.TextStyle) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let defaultSize = descriptor.pointSize // Dynamic size for the given text style

        guard let customFont = UIFont(name: name, size: defaultSize) else {
            // Fallback to the system preferred font if the custom font is not found
            return .preferredFont(forTextStyle: textStyle)
        }

        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: customFont)
    }
}

extension Font {
    static func bold(_ textStyle: UIFont.TextStyle) -> Font {
        return Font.custom("IBMPlexSans-Bold", size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }

    static func medium(_ textStyle: UIFont.TextStyle) -> Font {
        return Font.custom("IBMPlexSans-Medium", size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }

    static func semiBold(_ textStyle: UIFont.TextStyle) -> Font {
        return Font.custom("IBMPlexSans-Medium", size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }

    static func text(_ textStyle: UIFont.TextStyle) -> Font {
        return Font.custom("IBMPlexSans-Text", size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }

    static func regular(_ textStyle: UIFont.TextStyle) -> Font {
        return Font.custom("IBMPlexSans-Regular", size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }

    static func light(_ textStyle: UIFont.TextStyle) -> Font {
        return Font.custom("IBMPlexSans-Light", size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }
}

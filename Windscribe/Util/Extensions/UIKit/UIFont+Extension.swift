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

    static func medium(size: CGFloat) -> UIFont {
        return UIFont(name: "IBMPlexSans-Medium", size: size)!
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
        return UIFont.customPreferredFont(name: "IBMPlexSans-SemiBold", textStyle: textStyle)
    }

    static func text(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Text", textStyle: textStyle)
    }

    static func regular(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Regular", textStyle: textStyle)
    }

    static func light(textStyle: UIFont.TextStyle) -> UIFont {
        return UIFont.customPreferredFont(name: "IBMPlexSans-Light", textStyle: textStyle)
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
        .custom("IBMPlexSans-Bold", size: baseSize(for: textStyle), relativeTo: textStyle.toFontTextStyle())
    }

    static func medium(_ textStyle: UIFont.TextStyle) -> Font {
        .custom("IBMPlexSans-Medium", size: baseSize(for: textStyle), relativeTo: textStyle.toFontTextStyle())
    }

    static func semiBold(_ textStyle: UIFont.TextStyle) -> Font {
        .custom("IBMPlexSans-SemiBold", size: baseSize(for: textStyle), relativeTo: textStyle.toFontTextStyle())
    }

    static func text(_ textStyle: UIFont.TextStyle) -> Font {
        .custom("IBMPlexSans-Text", size: baseSize(for: textStyle), relativeTo: textStyle.toFontTextStyle())
    }

    static func regular(_ textStyle: UIFont.TextStyle) -> Font {
        .custom("IBMPlexSans", size: baseSize(for: textStyle), relativeTo: textStyle.toFontTextStyle())
    }

    static func light(_ textStyle: UIFont.TextStyle) -> Font {
        .custom("IBMPlexSans-Light", size: baseSize(for: textStyle), relativeTo: textStyle.toFontTextStyle())
    }

    /// Base point size per `UIFont.TextStyle`, matching Apple's dynamic type spec.
    private static func baseSize(for textStyle: UIFont.TextStyle) -> CGFloat {
#if os(tvOS)
        switch textStyle {
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption1: return 12
        case .caption2: return 11
        default: return 17
        }
#else
        switch textStyle {
        case .largeTitle: return 34
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption1: return 12
        case .caption2: return 11
        default: return 17
        }
#endif
    }
}

extension UIFont.TextStyle {
    func toFontTextStyle() -> Font.TextStyle {
#if os(tvOS)
        switch self {
        case .title1: return .title
        case .title2, .title3: return .title2
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption1, .caption2: return .caption
        default: return .body
        }
#else
        switch self {
        case .largeTitle: return .largeTitle
        case .title1: return .title
        case .title2, .title3: return .title2
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption1, .caption2: return .caption
        default: return .body
        }
#endif
    }
}

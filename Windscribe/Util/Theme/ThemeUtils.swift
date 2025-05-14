//
//  ThemeUtils.swift
//  Windscribe
//
//  Created by Thomas on 07/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import UIKit

enum ThemeUtils {
    static func wrapperColor(isDarkMode: Bool) -> UIColor {
        isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.10) : .midnightWithOpacity(opacity: 0.1)
    }

    static func primaryTextColor(isDarkMode: Bool) -> UIColor {
        isDarkMode ? UIColor.white : .midnight
    }

    static func primaryTextColorInvert(isDarkMode: Bool) -> UIColor {
        isDarkMode ? UIColor.midnight : .white
    }

    static func primaryTextColor50(isDarkMode: Bool) -> UIColor {
        isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.5) : .midnightWithOpacity(opacity: 0.5)
    }

    static func backgroundColor(isDarkMode: Bool) -> UIColor {
        isDarkMode ? UIColor.lightMidnight : .white
    }

    static func backButtonAsset(isDarkMode: Bool) -> String {
        isDarkMode ? ImagesAsset.DarkMode.prefBackIcon : ImagesAsset.prefBackIcon
    }

    static func closeButtonAsset(isDarkMode: Bool) -> String {
        isDarkMode ? ImagesAsset.closeIcon : ImagesAsset.closeIconMidnight
    }
    static func selectedTextColor(isDarkMode: Bool) -> UIColor {
        isDarkMode ? .seaGreen : .navyBlue
    }

    // MARK: - PART 1
    static func getVersionBorderColor(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.08) : UIColor.midnightWithOpacity(opacity: 0.08)
    }

    static func favEmptyIcon(isDarkMode: Bool) -> UIImage? {
        return isDarkMode ? UIImage(named: "\(ImagesAsset.favEmpty)-white") : UIImage(named: ImagesAsset.favEmpty)
    }

    static func getRobertTextColor(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.5) : UIColor.midnight
    }

    static func iconViewImage(isDarkMode: Bool) -> UIImage? {
        return isDarkMode ? UIImage(named: "\(ImagesAsset.externalLink)-white") : UIImage(named: ImagesAsset.externalLink)
    }

    static func getEmailViewColor(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.5) : UIColor.midnight
    }

    static func prefRightIcon(isDarkMode: Bool) -> UIImage? {
        return isDarkMode ? UIImage(named: "\(ImagesAsset.prefRightIcon)-white") : UIImage(named: ImagesAsset.prefRightIcon)
    }

    static func getEmailTextColor(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.unconfirmedYellow(opacity: 0.1) : UIColor.pumpkinOrangeWithOpacity(opacity: 0.1)
    }

    static func getConfirmLabelColor(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.unconfirmedYellow : .pumpkinOrange
    }

    static func dropDownIcon(isDarkMode: Bool) -> UIImage? {
        return isDarkMode ? UIImage(named: "\(ImagesAsset.dropDownIcon)-white") : UIImage(named: ImagesAsset.dropDownIcon)
    }

    static func switchOffImage(isDarkMode: Bool) -> UIImage? {
        return isDarkMode ? UIImage(named: ImagesAsset.SwitchButton.off) : UIImage(named: ImagesAsset.SwitchButton.offBlack)
    }

    static func interfaceStyle(isDarkMode: Bool) -> UIUserInterfaceStyle {
        return isDarkMode ? .dark : .light
    }

    static func editImage(isDarkMode: Bool) -> UIImage? {
        return isDarkMode ? UIImage(named: ImagesAsset.DarkMode.edit) : UIImage(named: ImagesAsset.edit)
    }
}

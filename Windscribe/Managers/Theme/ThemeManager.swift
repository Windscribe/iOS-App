//
//  ThemeManager.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol ThemeManager {
    var darkTheme: BehaviorSubject<Bool> { get }
    func getIsDarkTheme() -> Bool
}

protocol ThemeUtilsType {
    var dropDownIcon: UIImage? { get }
    var favEmptyIcon: UIImage? { get }
    var iconViewImage: UIImage? { get }
    var prefRightIcon: UIImage? { get }
    var switchOffImage: UIImage? { get }
    var wrapperColor: UIColor { get }
    var primaryTextColor: UIColor { get }
    var primaryTextColorInvert: UIColor { get }
    var primaryTextColor50: UIColor { get }
    var backgroundColor: UIColor { get }
    var backButtonAsset: String { get }
    var closeButtonAsset: String { get }
    func getVersionBorderColor() -> UIColor
    func getRobertTextColor() -> UIColor
    func getEmailViewColor() -> UIColor
    func getEmailTextColor() -> UIColor
    func getConfirmLabelColor() -> UIColor
    func interfaceStyle(isDarkMode: Bool) -> UIUserInterfaceStyle
}

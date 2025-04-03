//
//  WTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-07-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Swinject
import SwipeCellKit
import UIKit

class WTableViewCell: SwipeTableViewCell {
    lazy var themeManager = Assembler.resolve(ThemeManager.self)

    // let isDark = themeManager.getIsDarkTheme()

//    var fullFavImage: UIImage? {
//        if !themeManager.getIsDarkTheme() {
//            return UIImage(named: ImagesAsset.favFull)
//        } else {
//            return UIImage(named: ImagesAsset.DarkMode.favFull)
//        }
//    }

//    var emptyFavImage: UIImage? {
//        if !themeManager.getIsDarkTheme() {
//            return UIImage(named: ImagesAsset.favEmpty)
//        } else {
//            return UIImage(named: ImagesAsset.DarkMode.favEmpty)
//        }
//    }

    var proNodeIconImage: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.proNodeIcon)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.proNodeIcon)
        }
    }

    var cellSignalBarsLow: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.CellSignalBars.low)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.cellSignalBarsLow)
        }
    }

    var cellSignalBarsMed: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.CellSignalBars.medium)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.cellSignalBarsMedium)
        }
    }

    var cellSignalBarsFull: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.CellSignalBars.full)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.cellSignalBarsFull)
        }
    }

    var cellSignalBarsDown: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.CellSignalBars.low)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.cellSignalBarsDown)
        }
    }

    var locationDownIcon: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.locationDown)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.locationDown)
        }
    }

    var staticIPDc: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.staticIPdc)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.staticIPdc)
        }
    }

    var staticIPResidential: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.staticIPres)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.staticIPres)
        }
    }

    var tenGigIcon: UIImage? {
        if !themeManager.getIsDarkTheme() {
            return UIImage(named: ImagesAsset.tenGig)
        } else {
            return UIImage(named: ImagesAsset.DarkMode.tenGig)
        }
    }

    func getSignalLevel(minTime: Int) -> Int {
        var signalLevel = 0
        if minTime <= 100 {
            signalLevel = 3
        } else if minTime <= 250 {
            signalLevel = 2
        } else {
            signalLevel = 1
        }
        return signalLevel
    }
}
